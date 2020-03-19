module RedmineEmlAttachments
  module MailHandlerPatch

    private

    EML_MEDIA_TYPE = 'message/rfc822'
    FAKE_MEDIA_TYPE = 'piccio/eml'

    def add_attachments(obj)
      RedmineEmlAttachments::EmlAttachmentsLogger.write(:debug,  'BEGIN #add_attachments')
      RedmineEmlAttachments::EmlAttachmentsLogger.write(
        :debug,   "Email Attachments before fix: #{email.attachments.inspect}")

      # temporary variable to avoid infinite loop if add attachments directly to email.attachments inside
      # email.parts.each loop
      attachments = []

      # checking multipart
      RedmineEmlAttachments::EmlAttachmentsLogger.write(:debug,  "Checking multipart")
      if email.parts
        email.parts.each do |part|
          RedmineEmlAttachments::EmlAttachmentsLogger.write(:debug, "part: #{part.inspect}")

          #  inspect the email part's header
          RedmineEmlAttachments::EmlAttachmentsLogger.write(
            :debug, "content dispostition: #{part.content_disposition}")
          RedmineEmlAttachments::EmlAttachmentsLogger.write(
            :debug, "content type: #{part.content_type}")
          content_disposition_presentation_style =
            part.content_disposition.partition(';').first unless part.content_disposition.blank?
          media_type = part.content_type.partition(';').first unless part.content_type.blank?

          # find eml attachment
          if content_disposition_presentation_style == 'attachment' && media_type == EML_MEDIA_TYPE
            RedmineEmlAttachments::EmlAttachmentsLogger.write(
              :debug, "Found eml attachment in parts section")

            # extract file contents
            content = part.decoded

            # infer the file name
            filename_from_content_disposition =
              part.content_disposition.match(/\Aattachment; filename="(.*)"/)[1] unless
              part.content_disposition.match(/\Aattachment; filename="(.*)"/).nil?
            RedmineEmlAttachments::EmlAttachmentsLogger.write(
              :debug, "filename from content disposition: #{filename_from_content_disposition}")
            filename_from_content_type =
              part.content_type.match(/\A.*; name="(.*)"/)[1] unless part.content_type.match(/\A.*; name="(.*)"/).nil?
            RedmineEmlAttachments::EmlAttachmentsLogger.write(
              :debug, "filename from content type: #{filename_from_content_type}")
            # outlook doesn't insert file name neither in content_disposition neither in content_type
            # then try to extract filename from mail subject
            filename_from_subject = "#{Mail.new(content).subject}.eml"
            RedmineEmlAttachments::EmlAttachmentsLogger.write(
              :debug, "filename from subject: #{filename_from_subject}")
            filename = filename_from_content_disposition || filename_from_content_type || filename_from_subject
            RedmineEmlAttachments::EmlAttachmentsLogger.write(:debug, "filename: #{filename}")

            # use a fake media type because when adding attachment (see below, row 71) the 'Mail' gem
            # rejects 'message/rfc822' attachments
            attachments << {
              filename: filename,
              mime_type: FAKE_MEDIA_TYPE,
              content: content
            }
            RedmineEmlAttachments::EmlAttachmentsLogger.write(:debug,   "Attachment temporary stored")
          end
        end
        RedmineEmlAttachments::EmlAttachmentsLogger.write(
          :debug,
          "Attachments found: #{attachments.map { |x| x.select { |k, v| k != :content } }.inspect}")

        attachments.each do |attachment|
          # add attachments to the mail object using 'Mail' gem
          email.attachments[attachment[:filename]] = {
            mime_type: attachment[:mime_type],
            content: attachment[:content]
          }
          RedmineEmlAttachments::EmlAttachmentsLogger.write(
            :debug,   "Attachment #{attachment[:filename]} added to email")
        end
      end

      RedmineEmlAttachments::EmlAttachmentsLogger.write(
        :debug,   "Email Attachments after fix: #{email.attachments.inspect}")

      # save attachments through original method
      super

      # fix stored eml attachments with correct media type
      # note: don't use obj.attachments.where because object may not be persistent
      obj.attachments.select{ |x| x.content_type == FAKE_MEDIA_TYPE }.each do |attachment|
        RedmineEmlAttachments::EmlAttachmentsLogger.write(
          :debug,   "fix attachment content_type of #{attachment.filename}")
        attachment.update_attributes!(content_type: EML_MEDIA_TYPE)
      end

      RedmineEmlAttachments::EmlAttachmentsLogger.write(
        :debug, "Object Attachments: #{obj.attachments.inspect}")

      RedmineEmlAttachments::EmlAttachmentsLogger.write(:debug,  'END #add_attachments')
    end

  end
end