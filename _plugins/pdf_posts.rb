# PDF Posts Plugin for Jekyll
# Copies PDFs from _pdfs/ to assets/pdfs/

module Jekyll
  class PdfCopyGenerator < Generator
    safe true
    priority :low

    def generate(site)
      pdfs_dir = File.join(site.source, '_pdfs')
      return unless File.directory?(pdfs_dir)

      Dir.glob(File.join(pdfs_dir, '*.pdf')).each do |pdf_path|
        site.static_files << PdfStaticFile.new(
          site,
          site.source,
          '_pdfs',
          File.basename(pdf_path)
        )
      end
    end
  end

  class PdfStaticFile < StaticFile
    def destination(dest)
      File.join(dest, 'assets', 'pdfs', @name)
    end
  end
end
