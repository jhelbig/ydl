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
      name = download_name(format).gsub(/\.mp\d$/) { "" }
      dir = File.expand_path(File.join(ENV.fetch("YDL_PATH", "~/ydl_downloads")))
      Dir.mkdir_p(dir)
      Dir.cd(dir)

      ydl_args = [
        "-f", format.id,
        "-o", %<#{name}.%(ext)s>,
        @url
      ]

      if format.resolution == "Audio"
        ydl_args << "--audio-format"
        ydl_args << "mp3"
        ydl_args << "-x"
      else
        ydl_args << "--recode-video"
        ydl_args << "mp4"
      end

      status = Process.run("youtube-dl", ydl_args)

      File.join(dir, download_name(format))
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
