class Document < Sequel::Model
  IMAGE_CONTENT_TYPE = {'.bmp'=>'bmp', '.jpeg'=>'jpeg', '.jpg'=>'jpeg',
                        '.gif'=>'gif', '.png'=>'png'}

  def content_type
    if ext = IMAGE_CONTENT_TYPE[File.extname(path.downcase)]
      "image/#{ext}"
    else
      "application/octet-stream"
    end
  end

  def viewable?
    content_type != "application/octet-stream"
  end
end
