class OldDataImportService
  # 使い方: OldDataImportService.new.call

  def call
    json_path = Rails.root.join('storage', 'old_data', 'data.json')
    unless File.exist?(json_path)
      puts "Data file not found: #{json_path}"
      return
    end

    data = JSON.parse(File.read(json_path))
    account = Account.first

    unless account
      puts "No account found. Please create an account first."
      return
    end

    data.each do |item|
      import_post(item, account)
    end
  end

  private

  def import_post(item, account)
    aid = item['aid'][0...14]
    
    post = Post.find_or_initialize_by(aid: aid)
    post.account = account
    post.content = item['content']
    post.created_at = item['created_at']
    
    if post.save
      puts "Imported Post: #{aid}"
    else
      puts "Failed to import Post #{aid}: #{post.errors.full_messages.join(', ')}"
      return
    end

    # Handle images
    item['images'].each do |img_data|
      import_image(post, img_data, account)
    end

    # Handle videos
    item['videos'].each do |vid_data|
      import_video(post, vid_data, account)
    end
  end

  def import_image(post, img_data, account)
    original_aid = img_data['aid']
    img_aid = original_aid[0...14]
    
    # Check if image already linked
    return if post.images.exists?(aid: img_aid)

    image = Image.find_or_initialize_by(aid: img_aid)
    
    if image.new_record?
      file_path = find_file('images', original_aid)
      unless file_path
        puts "Image file not found for AID: #{original_aid}"
        return
      end

      image.account = account
      image.image = create_uploaded_file(file_path)
      
      if image.save
        puts "  Imported Image: #{img_aid}"
      else
        puts "  Failed to import Image #{img_aid}: #{image.errors.full_messages.join(', ')}"
        return
      end
    end
    
    post.images << image
  end

  def import_video(post, vid_data, account)
    original_aid = vid_data['aid']
    vid_aid = original_aid[0...14]

    return if post.videos.exists?(aid: vid_aid)

    video = Video.find_or_initialize_by(aid: vid_aid)

    if video.new_record?
      file_path = find_file('videos', original_aid)
      unless file_path
        puts "Video file not found for AID: #{original_aid}"
        return
      end

      video.account = account
      video.video = create_uploaded_file(file_path)

      if video.save
        puts "  Imported Video: #{vid_aid}"
      else
        puts "  Failed to import Video #{vid_aid}: #{video.errors.full_messages.join(', ')}"
        return
      end
    end

    post.videos << video
  end

  def find_file(type, aid)
    # Search for file with any extension
    Dir.glob(Rails.root.join('storage', 'old_data', type, "#{aid}.*")).first
  end

  def create_uploaded_file(path)
    ActionDispatch::Http::UploadedFile.new(
      tempfile: File.open(path),
      filename: File.basename(path),
      type: Mime::Type.lookup_by_extension(File.extname(path).delete('.'))&.to_s || 'application/octet-stream'
    )
  end
end
