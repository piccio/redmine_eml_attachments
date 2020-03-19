require 'redmine_eml_attachments/mail_handler_patch'
require 'redmine_eml_attachments/eml_attachments_logger'

Rails.configuration.to_prepare do
  unless MailHandler.included_modules.include? RedmineEmlAttachments::MailHandlerPatch
    MailHandler.prepend(RedmineEmlAttachments::MailHandlerPatch)
  end
end

Redmine::Plugin.register :redmine_eml_attachments do
  name 'Redmine Eml Attachments'
  author 'Roberto Piccini'
  description 'accept eml files as attachments when receiving issues from emails, solve https://www.redmine.org/issues/8093'
  version '1.0.0'
  url 'https://github.com/piccio/redmine_eml_attachments'
  author_url 'https://github.com/piccio'

  settings default: { 'enable_log' => false }, partial: 'settings/eml_attachments'
end
