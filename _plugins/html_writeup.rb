# HTML Writeup Plugin for Jekyll
# Handles both protected (base64-embedded) and unprotected (copied to assets) HTML writeups

require 'base64'

module Jekyll
  # Protected HTML: reads from _protected_pdfs/, base64-encodes into page data
  class ProtectedHtmlGenerator < Generator
    safe true
    priority :high

    def generate(site)
      protected_dir = File.join(site.source, '_protected_pdfs')
      return unless File.directory?(protected_dir)

      site.posts.docs.each do |post|
        next unless post.data['protected_html']

        html_filename = post.data['protected_html']
        html_path = File.join(protected_dir, html_filename)

        if File.exist?(html_path)
          html_content = File.binread(html_path)
          base64_data = Base64.strict_encode64(html_content)
          post.data['html_data_uri'] = "data:text/html;base64,#{base64_data}"
          Jekyll.logger.info "Protected HTML:", "Embedded #{html_filename} (#{html_content.length} bytes) in #{post.data['title']}"
        else
          Jekyll.logger.error "Protected HTML:", "FILE NOT FOUND: #{html_path}"
        end
      end
    end
  end

  # Unprotected HTML: copies from _htmlposts/ to assets/html/
  class HtmlCopyGenerator < Generator
    safe true
    priority :low

    def generate(site)
      htmlposts_dir = File.join(site.source, '_htmlposts')
      return unless File.directory?(htmlposts_dir)

      Dir.glob(File.join(htmlposts_dir, '*.html')).each do |html_path|
        site.static_files << HtmlStaticFile.new(
          site,
          site.source,
          '_htmlposts',
          File.basename(html_path)
        )
      end
    end
  end

  class HtmlStaticFile < StaticFile
    def destination(dest)
      File.join(dest, 'assets', 'html', @name)
    end
  end
end
