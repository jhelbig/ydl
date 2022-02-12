require "./ydl/*"
require "json"

module Ydl
  class Video
    getter title : String
    getter url : String
    getter best_formats : Array(Ydl::Format)
    getter audio_formats : Array(Ydl::Format)
    getter full_formats : Array(Ydl::Format)

    def initialize(url : String)
      output = IO::Memory.new
      Process.run("youtube-dl", ["-J", url], output: output)
      output.close

      begin
        obj = JSON.parse(output.to_s)
      rescue
        raise "Invalid url"
      end

      initialize(obj)
    end

    def initialize(json : JSON::Any)
      @title = json["title"].as_s
      @url = json["webpage_url"].as_s
      best_format_group = json["format_id"].as_s.split(/\+/)
      @audio_formats = json["formats"].as_a
        .select { |f| f["format_note"].as_s.includes?("tiny") }
        .map { |f| Ydl::Format.new(f) }
      @full_formats = json["formats"].as_a
        .select { |f| !f["format_note"].as_s.includes?("tiny") }
        .map { |f| Ydl::Format.new(f) }
      @best_formats = json["formats"].as_a
        .select { |f| f["format_id"].as_s.includes?(best_format_group[0]) || f["format_id"].as_s.includes?(best_format_group[1]) }
        .map { |f| Ydl::Format.new(f) }
    end

    def download_name(format : Ydl::Format)
      if format.resolution == "Audio"
        %<#{@title.scrub("").gsub(/[\/\\]/, "_")} - (#{format.quality}hz).mp3>
      else
        %<#{@title.scrub("").gsub(/[\/\\]/, "_")} - (#{format.quality}p).mp4>
      end
    end

    def download(id : String)
      format = (@audio_formats + @full_formats).find { |f| f.id == id }

      download(format.not_nil!)
    end

    def download(format : Ydl::Format, filename : String = "")
      name = download_name(format).gsub(/\.mp\d$/) { "" }
      dir = File.expand_path(File.join(ENV.fetch("YDL_PATH", "~/ydl_downloads")))
      Dir.mkdir_p(dir)
      Dir.cd(dir)

      if filename == ""
        filename = %<#{name}.%(ext)s>
      else
        filename = %<#{filename}.%(ext)s>
      end
  
      ydl_args = [
        "-f", format.id,
        "-o", filename,
        @url,
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

    def download_and_mux(formats : Array(Ydl::Format))
      audio_path = ""
      video_path = ""
      name = ""
      dir = File.expand_path(File.join(ENV.fetch("YDL_PATH", "~/ydl_downloads")))
      Dir.mkdir_p(dir)
      Dir.cd(dir)
      formats.each{|format|
        name = download_name(format).gsub(/\.mp\d$/) { "" }

        ydl_args = [
          "-f", format.id,
          "-o", %<raw_#{name}.%(ext)s>,
          @url,
        ]

        if format.resolution == "Audio"
          ydl_args << "--audio-format"
          ydl_args << "mp3"
          ydl_args << "-x"
          audio_path = "#{dir}/raw_#{download_name(format)}"
        else
          ydl_args << "--recode-video"
          ydl_args << "mp4"
          video_path = "#{dir}/raw_#{download_name(format)}"
        end

        status = Process.run("youtube-dl", ydl_args)

        File.join(dir, download_name(format))
      }
      if audio_path != "" && video_path != ""
        ffmpeg_args = [
          "-i", video_path,
          "-i", audio_path,
          "-y",
          "-strict",
          "-2",
          "-c:v", "copy",
          "-c:a", "aac",
          "-map", "0:v:0",
          "-map", "1:a:0",
          "#{name}.mp4"
        ]
        status = Process.run("ffmpeg", ffmpeg_args)
        FileUtils.rm_rf([video_path, audio_path])
        File.join(dir, "#{name}.mp4")
      end
    end
  end

  struct Format
    getter id : String
    getter resolution : String
    getter name : String
    getter ydl_name : String
    getter quality : Int32
    getter filesize : Int64
    getter extension : String
    getter quality_grade : Int32

    def initialize(f : JSON::Any)
      f = f.as_h
      @id = f["format_id"].as_s
      @filesize = f["filesize"].as_i64 rescue 0.to_i64
      @extension = f["ext"].as_s
      @quality_grade = f["quality"].as_i

      @resolution = "Audio"

      begin
        @resolution = %<#{f["width"].as_i}x#{f["height"].as_i}>
      rescue
        # puts("It appeared to be a video but had null resolution. Treating as audio")
      end

      if f["format_note"] == "tiny"
        @quality = f["abr"].as_f.ceil.to_i rescue 0
        @name = "#{@quality}hz"
      else
        @quality = f["format_note"].as_s.gsub(/p$/i, "").to_i
        @name = f["format_note"].as_s
      end

      @ydl_name = f["format"].as_s
    end

    def attributes() : Hash(String, String | Int32 | Int64)
      return {
        "id" => @id,
        "resolution" => @resolution,
        "name" => @name,
        "ydl_name" => @ydl_name,
        "quality" => @quality,
        "filesize" => @filesize,
        "extension" => @extension,
        "quality_grade" => @quality_grade
      }
    end
  end
end
