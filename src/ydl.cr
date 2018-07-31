require "./ydl/*"
require "JSON"

module Ydl
  class Video
    getter title : String
    getter url : String
    getter audio_formats : Array(Ydl::Format)
    getter full_formats : Array(Ydl::Format)

    def initialize(url : String)
      output = IO::Memory.new()
      Process.run("youtube-dl", ["-J", url], output: output)
      output.close
      obj = JSON.parse(output.to_s)

      initialize(obj)
    end

    def initialize(json : JSON::Any)
      @title = json["title"].as_s
      @url = json["webpage_url"].as_s
      # @formats = json["formats"].as_a
      #   .select { |f| f["ext"].as_s == "mp4" || f["format_note"].as_s.includes?("audio") } 
      #   .map { |f| Ydl::Format.new(f) } 
      @audio_formats = json["formats"].as_a
        .select { |f| f["format_note"].as_s.includes?("audio") }
        .map { |f| Ydl::Format.new(f) }
      @full_formats = json["formats"].as_a
        .select { |f| f["vcodec"] != "none" && f["acodec"] != "none" }
        .map { |f| Ydl::Format.new(f) }
    end

    def download_name(format : Ydl::Format)
      if format.resolution == "Audio"
        %<#{@title} - (#{format.quality}hz).mp3>
      else
        %<#{@title} - (#{format.quality}p).mp4>
      end
    end

    def download(format : Ydl::Format)
      output = IO::Memory.new()
    end
  end


  struct Format
    getter id : String
    getter resolution : String
    getter name : String
    getter ydl_name : String
    getter quality : Int32
    
    def initialize(f : JSON::Any)
      f = f.as_h
      @id = f["format_id"].as_s
      if f.has_key?("width")
        @resolution = %<#{f["width"]}x#{f["height"]}>
      else
        @resolution = "Audio"
      end
      @name = f["format_note"].as_s
      @ydl_name = f["format"].as_s

      if @resolution == "Audio"
        @quality = f["abr"].as_i
      else
        @quality = f["height"].as_i
      end
    end
  end
end
