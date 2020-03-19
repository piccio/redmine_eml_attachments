module RedmineEmlAttachments
  class EmlAttachmentsLogger < Logger
    def self.write(level, message)
      if Setting.plugin_redmine_eml_attachments['enable_log'] == 'true'
        logger ||= new("#{Rails.root}/log/eml_attachments.log")
        logger.send(level, message)
      end
    end
  end
end
