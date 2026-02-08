# HTML Writeup Plugin for Jekyll
# Handles both protected (inline) and unprotected (copied to assets) HTML writeups
# Extracts body content and styles from Obsidian HTML exports at build time

require 'base64'

module Jekyll
  # Protected HTML: reads from _protected_pdfs/, extracts body + styles into page data
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
          html_content = File.read(html_path, encoding: 'UTF-8')

          # Extract all <style> tags from the document
          styles = html_content.scan(/<style[^>]*>.*?<\/style>/m).join("\n")

          # Extract body inner content
          body_match = html_content.match(/<body[^>]*>(.*)<\/body>/m)
          body_inner = body_match ? body_match[1] : ''

          # Extract body classes
          body_class_match = html_content.match(/<body[^>]*class="([^"]*)"/)
          body_classes = body_class_match ? body_class_match[1] : ''

          # Also keep the full file as base64 for download button
          raw_bytes = File.binread(html_path)
          base64_data = Base64.strict_encode64(raw_bytes)

          post.data['html_styles'] = styles
          post.data['html_body'] = body_inner
          post.data['html_body_classes'] = body_classes
          post.data['html_data_uri'] = "data:text/html;base64,#{base64_data}"

          Jekyll.logger.info "Protected HTML:", "Extracted #{html_filename} (#{html_content.length} bytes, body: #{body_inner.length} bytes) in #{post.data['title']}"
        else
          Jekyll.logger.error "Protected HTML:", "FILE NOT FOUND: #{html_path}"
        end
      end
    end
  end

  # Unprotected HTML: reads file, extracts body + styles, copies original to assets
  class UnprotectedHtmlGenerator < Generator
    safe true
    priority :high

    def generate(site)
      site.posts.docs.each do |post|
        next unless post.data['layout'] == 'html_writeup'
        next unless post.data['html_file']
        next if post.data['protected_html']

        # Determine source file from html_file path (e.g. /assets/html/Facts.html)
        basename = File.basename(post.data['html_file'])
        htmlposts_dir = File.join(site.source, '_htmlposts')
        html_path = File.join(htmlposts_dir, basename)

        next unless File.exist?(html_path)

        html_content = File.read(html_path, encoding: 'UTF-8')

        styles = html_content.scan(/<style[^>]*>.*?<\/style>/m).join("\n")

        body_match = html_content.match(/<body[^>]*>(.*)<\/body>/m)
        body_inner = body_match ? body_match[1] : ''

        body_class_match = html_content.match(/<body[^>]*class="([^"]*)"/)
        body_classes = body_class_match ? body_class_match[1] : ''

        post.data['html_styles'] = styles
        post.data['html_body'] = body_inner
        post.data['html_body_classes'] = body_classes

        Jekyll.logger.info "HTML Writeup:", "Extracted #{basename} (body: #{body_inner.length} bytes) in #{post.data['title']}"
      end
    end
  end

  # Copies HTML files from _htmlposts/ to assets/html/
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
