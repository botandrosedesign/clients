class ImportCommentWorker
  include Sidekiq::Worker

  def perform comment_id
    comment = Comment.find(comment_id)
    incoming_email = IncomingEmail.find(comment.smtp_id)
    @mail = Mail.read_from_string(incoming_email.read)
    result = CommentOperations::Create.call(
      story:,
      comment_attrs:,
      current_user: user,
      comment:,
    )
    match_result(result) do |on|
      on.success do |comment|
        incoming_email.destroy
      end
      on.failure do |comment|
        # noop
      end
    end
  end

  private

  def match_result(result)
    Dry::Matcher::ResultMatcher.call(result) { |on| yield on }
  end

  def project
    @project ||= Project.find_by!(name: project_name)
  end

  def project_name
    @mail.subject.match(REGEX)[1]
  end

  def story
    @story ||= project.stories.find_by!(title: story_name)
  end

  def story_name
    @mail.subject.match(REGEX)[2]
  end

  REGEX = /\[(.+)\] (.+)$/

  def user
    @user ||= project.users.find_by!(email: @mail.from.first)
  end

  def comment_attrs
    email_text = extract_text(@mail)
    body = email_text.split(/\r\n\r\n.+BARD Tracker <[^>]+>/)[0]
    { body:, user: }
  end

  def extract_text(part)
    if part.multipart?
      # If the part is multipart, recursively extract text from each subpart
      text = ''
      part.parts.each { |subpart| text += extract_text(subpart) }
      text
    elsif part.content_type =~ /^text\/plain/
      # If the part is plain text, return its body
      part.body.decoded
    else
      '' # Return empty string for other types of parts (e.g., attachments)
    end
  end
end


