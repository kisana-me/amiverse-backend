class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  include TokenTools

  private

  NAME_ID_REGEX = /\A[a-zA-Z0-9_]+\z/
  BASE64_URLSAFE_REGEX = /\A[a-zA-Z0-9\-_]+\z/
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d-]+(\.[a-z\d-]+)*\.[a-z]+\z/i

  def set_aid
    self.aid ||= SecureRandom.base36(14)
  end

  def full_url(path)
    URI.join(ENV.fetch("BACK_URL"), path).to_s
  end
end
