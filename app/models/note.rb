class Note < ApplicationRecord
  belongs_to :user
  belongs_to :story, touch: true

  has_many_attached :attachments

  before_save :cache_user_name

  validates :note, presence: true

  delegate :project, to: :story

  def to_csv
    user_name = user ? user.name : I18n.t('author unknown')
    created_date = I18n.l created_at, format: :note_date

    "#{note} (#{user_name} - #{created_date})"
  end

  private

  def cache_user_name
    self.user_name = user.name if user.present?
  end
end
