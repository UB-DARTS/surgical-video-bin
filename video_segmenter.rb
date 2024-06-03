require 'fileutils'

# Videos
class Video
  attr_reader :file_path, :output_dir, :fps, :segment_duration

  def initialize(file_path, output_dir)
    @file_path = file_path
    @output_dir = output_dir
    @fps = get_fps
    @segment_duration = calculate_segment_duration
  end

  def get_fps
    command = "ffmpeg -i '#{file_path}' 2>&1"
    result = `#{command}`
    print result
    print 'do you make it here?'
    fps = nil

    result.each_line do |line|
      next unless line.include?(' fps')

      parts = line.split(',')
      parts.each do |part|
        puts part
        next unless part.include?(' fps')

        print '---'
        fps = part.strip.split(',').first.to_f
        break
      end
      break if fps
    end
    fps
  end

  def calculate_segment_duration
    19_000.0 / @fps
  end

  def segment_video
    video_name = File.basename(file_path, File.extname(file_path))
    video_output_dir = File.join(output_dir, video_name)
    FileUtils.mkdir_p(video_output_dir)

    ffmpeg_command = <<-CMD
      ffmpeg -i "#{file_path}" -c copy -map 0 -segment_time #{segment_duration} -g 30 -force_key_frames "expr:gte(t,n_forced*#{segment_duration})" -f segment -reset_timestamps 1 -copyts "#{video_output_dir}/#{video_name}_segment_%03d#{File.extname(file_path)}"
    CMD

    system(ffmpeg_command)
  end
end

# Segment videos to 19k frames
class VideoSegmenter
  attr_reader :input_dir, :output_dir, :videos

  def initialize(input_dir, output_dir)
    @input_dir = input_dir
    @output_dir = output_dir
    @videos = []
    FileUtils.mkdir_p(output_dir)
    ensure_ffmpeg_installed
    load_videos
  end

  def ensure_ffmpeg_installed
    return if system('ffmpeg -version > /dev/null 2>&1')

    puts 'ffmpeg is not installed. Please install ffmpeg and ensure it is in Path.'
    exit(1)
  end

  def load_videos
    Dir.glob(File.join(input_dir, '*.{mp4,mov,ai,mkv,mpg}')).each do |video_file|
      videos << Video.new(video_file, output_dir)
    end
  end

  def segment_videos
    videos.each(&:segment_video)
    puts 'Video segmentation complete'
  end
end

input_dir = ''
output_dir = ''

segmenter = VideoSegmenter.new(input_dir, output_dir)
segmenter.segment_videos
