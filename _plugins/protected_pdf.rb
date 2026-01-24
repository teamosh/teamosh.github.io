# Che smotrish sudya?
# PDFs here are embedded and encrypted. No direct access.

require 'base64'

module Jekyll
  class ProtectedPdfGenerator < Generator
    safe true
    priority :high

    def generate(site)
      protected_pdfs_dir = File.join(site.source, '_protected_pdfs')
      Jekyll.logger.info "Protected PDF:", "Looking in #{protected_pdfs_dir}"

      unless File.directory?(protected_pdfs_dir)
        Jekyll.logger.warn "Protected PDF:", "Directory not found: #{protected_pdfs_dir}"
        return
      end

      # List files in directory
      files = Dir.entries(protected_pdfs_dir).reject { |f| f.start_with?('.') }
      Jekyll.logger.info "Protected PDF:", "Files found: #{files.join(', ')}"

      site.posts.docs.each do |post|
        next unless post.data['protected_pdf']

        pdf_filename = post.data['protected_pdf']
        pdf_path = File.join(protected_pdfs_dir, pdf_filename)
        Jekyll.logger.info "Protected PDF:", "Looking for #{pdf_filename} at #{pdf_path}"

        if File.exist?(pdf_path)
          pdf_content = File.binread(pdf_path)
          base64_data = Base64.strict_encode64(pdf_content)
          post.data['pdf_data_uri'] = "data:application/pdf;base64,#{base64_data}"
          Jekyll.logger.info "Protected PDF:", "Embedded #{pdf_filename} (#{pdf_content.length} bytes) in #{post.data['title']}"
        else
          Jekyll.logger.error "Protected PDF:", "FILE NOT FOUND: #{pdf_path}"
        end
      end
    end
  end
end
