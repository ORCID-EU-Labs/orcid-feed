# -*- coding: utf-8 -*-

require 'addressable/uri'

class Work < BibTeX::Entry

  attr_accessor :doi, :url, :number, :volume, :pages

  WORK_TYPES = { article:       "JOURNAL_ARTICLE",
                 inproceedings: "CONFERENCE_PROCEEDINGS",
                 misc:          "OTHER" }

  
  def initialize(work, author)
    # if work is already in bibtex format
    if work["work-citation"] and work["work-citation"]["work-citation-type"].upcase == "BIBTEX"
      entry = BibTeX.parse(work["work-citation"]["citation"])[0]
      
      # Fix missing or malformed author field
      entry.author = author if entry.author.to_s == ""
      entry.author.gsub!(";", "")
      unless entry.author.to_s.include?("and") or entry.author.to_s.count(" ") < 3
        entry.author = entry.author.gsub(",", " and ")
      end

      # Fix missing title
      entry.title = "No title" unless entry.title

      super(entry.fields)
      self.type = entry.type
  	else
    	type = WORK_TYPES.key(work["work-type"]) || :misc
    	title = work["work-title"] ? work["work-title"]["title"]["value"] : "No title"

      super({:type => type,
      	     :title => title,
             :author => author})

      # Optional attributes
      self.journal = work["work-title"]["subtitle"]["value"] if work["work-title"] and work["work-title"]["subtitle"]
      self.year = work["publication-date"]["year"]["value"] if work["publication-date"]
    end

    if work["work-external-identifiers"] and work["work-external-identifiers"]["work-external-identifier"] and work["work-external-identifiers"]["work-external-identifier"][0]["work-external-identifier-type"].upcase == "DOI"
      doi = work["work-external-identifiers"]["work-external-identifier"][0]["work-external-identifier-id"]["value"]
      doi = doi.gsub(/(?i:DOI):?\s?(10\.\S+)/, '\1').strip
      self["doi"] = doi
      self["url"] = Addressable::URI.escape "http://dx.doi.org/#{doi}"
    end
  end

  def hash
    "#{unique_title}_#{year}".hash
  end

  def ==(other)
    other.equal?(self) || ( other.instance_of?(self.class) && "#{other.unique_title}_#{other.year}" == "#{unique_title}_#{year}" )
  end

  alias :eql? :==

  def unique_title
    encoding_options = {
      :invalid           => :replace,  # Replace invalid byte sequences
      :undef             => :replace,  # Replace anything not defined in ASCII
      :replace           => ''         # Use a blank for those replacements
    }
    title.downcase.encode Encoding.find('ASCII'), encoding_options
  end
end
