class Account < Sequel::Model
  def before_create
    self.token = SecureRandom.hex(20)
    super
  end
end
