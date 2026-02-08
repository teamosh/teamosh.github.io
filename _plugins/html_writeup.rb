# HTML Writeup Plugin for Jekyll
# Handles both protected (inline) and unprotected (copied to assets) HTML writeups
# Extracts body content and styles from Obsidian HTML exports at build time

require 'base64'

module Jekyll
  module HtmlWriteupHelper
    # Scope CSS so it only affects .obsidian-writeup container
    def self.scope_css(styles_html)
      # Extract CSS content from <style> tags
      styles_html.gsub(/<style[^>]*>(.*?)<\/style>/m) do
        css = $1
        # Replace body/html selectors with .obsidian-writeup
        css = css.gsub(/\bhtml\b/, '.obsidian-writeup')
        css = css.gsub(/\bbody\b/, '.obsidian-writeup')
        "<style>#{css}</style>"
      end
    end

    def self.extract_html(html_content)
      # Extract all <style> tags from the document and scope them
      raw_styles = html_content.scan(/<style[^>]*>.*?<\/style>/m).join("\n")
      styles = scope_css(raw_styles)

      # Extract body inner content
      body_match = html_content.match(/<body[^>]*>(.*)<\/body>/m)
      body_inner = body_match ? body_match[1] : ''

      # Extract body classes
      body_class_match = html_content.match(/<body[^>]*class="([^"]*)"/)
      body_classes = body_class_match ? body_class_match[1] : ''

      { styles: styles, body: body_inner, body_classes: body_classes }
    end
  end

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
          extracted = HtmlWriteupHelper.extract_html(html_content)

          post.data['html_styles'] = extracted[:styles]
          post.data['html_body'] = extracted[:body]
          post.data['html_body_classes'] = extracted[:body_classes]

          Jekyll.logger.info "Protected HTML:", "Extracted #{html_filename} (#{html_content.length} bytes, body: #{extracted[:body].length} bytes) in #{post.data['title']}"
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

        basename = File.basename(post.data['html_file'])
        htmlposts_dir = File.join(site.source, '_htmlposts')
        html_path = File.join(htmlposts_dir, basename)

        next unless File.exist?(html_path)

        html_content = File.read(html_path, encoding: 'UTF-8')
        extracted = HtmlWriteupHelper.extract_html(html_content)

        post.data['html_styles'] = extracted[:styles]
        post.data['html_body'] = extracted[:body]
        post.data['html_body_classes'] = extracted[:body_classes]

        Jekyll.logger.info "HTML Writeup:", "Extracted #{basename} (body: #{extracted[:body].length} bytes) in #{post.data['title']}"
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
