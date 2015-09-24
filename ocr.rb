require './models.rb'

Dir.mkdir('tmp') unless File.directory?('tmp')
QUEUE = Queue.new

ocr = lambda do |document_id|
  if (d = Document[document_id]) && d.text.nil?
    tmp_name = "tmp/#{d.id}#{File.extname(d.path)}"
    txt_name = "tmp/#{d.id.to_s}.txt"
    begin
      File.write(tmp_name, d.image)
      print "OCR starting for document ##{d.id}"
      system('tesseract', tmp_name, txt_name[0...-4],
             [:out, :err]=>'/dev/null')
      puts ", finished"
      d.update(:text => File.read(txt_name)) if File.file?(txt_name)
    ensure
      File.delete(tmp_name) if File.file?(tmp_name)
      File.delete(txt_name) if File.file?(txt_name)
    end
  end
end

Thread.new do
  DB.listen('ocr',
            :after_listen=>proc{QUEUE.push nil},
            :loop=>true) do |_, _, document_id|
    QUEUE.push(document_id)
  end
end

QUEUE.pop

Document.where(:text=>nil).select_map(:id).each do |document_id|
  QUEUE.push(document_id)
end

while doc_id = QUEUE.pop
  ocr.call(doc_id)
end
