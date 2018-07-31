require "./spec_helper"
require "JSON"

describe Ydl::Video do
  video = Ydl::Video.new(JSON.parse(File.read(__DIR__ + "/full_response.json")))

  it "has a title" do
    video.title.should eq("Dungeon of the Endless Soundtrack (OST, 17 Tracks)")
  end

  it "has a url" do
    video.url.should eq("https://www.youtube.com/watch?v=B86eQWDMTAw")
  end

  it "has audio only formats" do
    video.audio_formats.size.should eq(5)
  end

  it "has full formats" do
    video.full_formats.size.should eq(5)
  end

  it "has sorted formats" do
    video.audio_formats.last.quality.should be > video.audio_formats.first.quality
    video.full_formats.last.quality.should be > video.full_formats.first.quality
  end

  it "has a download name for a video format" do
    format = video.full_formats.first
    video.download_name(format).should eq("Dungeon of the Endless Soundtrack (OST, 17 Tracks) - (144p).mp4")
  end

  it "has a download name for a audio format" do
    format = video.audio_formats.first
    video.download_name(format).should eq("Dungeon of the Endless Soundtrack (OST, 17 Tracks) - (50hz).mp3")
  end

  it "downloads the specified audio format" do
    format = video.audio_formats.first

    video.download(format).should eq("Done!")
  end
end

describe Ydl::Format do
  describe "Video format" do
    json = %<{ "http_headers": { "Accept-Charset": "ISO-8859-1,utf-8;q=0.7,*;q=0.7", "Accept-Language": "en-us,en;q=0.5", "Accept-Encoding": "gzip, deflate", "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0 (Chrome)" }, "tbr": 1730.05, "protocol": "https", "format": "248 - 1920x1080 (1080p)", "url": "https://r8---sn-b8u-gxj6.googlevideo.com/videoplayback?keepalive=yes&c=WEB&ei=rLxfW5P8OovaxQSa0oKgAQ&initcwndbps=368750&source=youtube&signature=718375BC6DBA90DB26676AA317444FD551DF65BC.18768C57BD87FAF5662C37EE4AEBEE12E2A98BED&clen=155617852&itag=248&gir=yes&mime=video%2Fwebm&key=yt6&ipbits=0&fvip=1&dur=3309.967&expire=1533022477&aitags=133%2C134%2C135%2C136%2C137%2C160%2C242%2C243%2C244%2C247%2C248%2C278&mm=31%2C29&mn=sn-b8u-gxj6%2Csn-gpv7enez&sparams=aitags%2Cclen%2Cdur%2Cei%2Cgir%2Cid%2Cinitcwndbps%2Cip%2Cipbits%2Citag%2Ckeepalive%2Clmt%2Cmime%2Cmm%2Cmn%2Cms%2Cmv%2Cpl%2Crequiressl%2Csource%2Cexpire&id=o-ANQT19lXs4wEPzxV4A0tmVA_909q4VpGEmA9vmBdJlOP&pl=20&ip=187.112.12.68&requiressl=yes&mt=1533000787&mv=m&ms=au%2Crdu&lmt=1494049580943158&ratebypass=yes", "vcodec": "vp9", "format_note": "1080p", "height": 1080, "downloader_options": { "http_chunk_size": 10485760 }, "width": 1920, "ext": "webm", "filesize": 155617852, "fps": 30, "format_id": "248", "player_url": "/yts/jsbin/player-vflW8WdD_/en_US/base.js", "quality": -1, "acodec": "none" }>

    format = Ydl::Format.new(JSON.parse(json))

    it "has an ydl name" do
      format.ydl_name.should eq("248 - 1920x1080 (1080p)")
    end

    it "has an id" do
      format.id.should eq("248")
    end

    it "has a resolution" do
      format.resolution.should eq("1920x1080")
    end

    it "has a name" do
      format.name.should eq("1080p")
    end

    it "has a quality" do
      format.quality.should eq(1080)
    end
  end

  describe "Audio format" do
    json = %<{
      "http_headers": {
        "Accept-Charset": "ISO-8859-1,utf-8;q=0.7,*;q=0.7",
        "Accept-Language": "en-us,en;q=0.5",
        "Accept-Encoding": "gzip, deflate",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:59.0) Gecko/20100101 Firefox/59.0 (Chrome)"
      },
      "format_note": "DASH audio",
      "protocol": "https",
      "format": "251 - audio only (DASH audio)",
      "url": "https://r8---sn-b8u-gxj6.googlevideo.com/videoplayback?keepalive=yes&c=WEB&ei=rLxfW5P8OovaxQSa0oKgAQ&signature=1BE8018024A143C42D0B6F63CB9964B3DA3286A1.99004ED6C7114E47F9759582DE7364AC77534FE0&source=youtube&clen=59508838&itag=251&gir=yes&mime=audio%2Fwebm&key=yt6&ipbits=0&fvip=1&dur=3310.001&expire=1533022477&mm=31%2C29&mn=sn-b8u-gxj6%2Csn-gpv7enez&sparams=clen%2Cdur%2Cei%2Cgir%2Cid%2Cinitcwndbps%2Cip%2Cipbits%2Citag%2Ckeepalive%2Clmt%2Cmime%2Cmm%2Cmn%2Cms%2Cmv%2Cpl%2Crequiressl%2Csource%2Cexpire&id=o-ANQT19lXs4wEPzxV4A0tmVA_909q4VpGEmA9vmBdJlOP&pl=20&lmt=1494048581985984&ip=187.112.12.68&requiressl=yes&mt=1533000787&mv=m&ms=au%2Crdu&initcwndbps=368750&ratebypass=yes",
      "vcodec": "none",
      "tbr": 179.135,
      "abr": 160,
      "player_url": "/yts/jsbin/player-vflW8WdD_/en_US/base.js",
      "downloader_options": {
        "http_chunk_size": 10485760
      },
      "ext": "webm",
      "filesize": 59508838,
      "format_id": "251",
      "quality": -1,
      "acodec": "opus"
    }>

    format = Ydl::Format.new(JSON.parse(json))

    it "has a resolution" do
      format.resolution.should eq("Audio")
    end

    it "has a quality" do
      format.quality.should eq(160)
    end
  end
end
