# -*- coding: utf-8 -*-

require 'addressable/uri'
require 'log4r'


class Work < BibTeX::Entry

  attr_accessor :doi, :url, :number, :volume, :pages

  WORK_TYPES = { article:       "JOURNAL_ARTICLE",
                 inproceedings: "CONFERENCE_PROCEEDINGS",
                 misc:          "OTHER" }

  def logger
    Log4r::Logger['test']    
  end
  
  def initialize(work, author)
    # if work is already in bibtex format
    if work["work-citation"] and work["work-citation"]["work-citation-type"].upcase == "BIBTEX"
      logger.debug "Creating citation from BibTeX string:\n" + work["work-citation"]["citation"]
      entry = BibTeX.parse(work["work-citation"]["citation"])[0]

      logger.debug "Got entry obj " + entry.ai
      
      # Fix missing or malformed author field
      entry.author = author if entry.author.to_s == ""
      entry.author.gsub!(";", "")
      unless entry.author.to_s.include?("and") or entry.author.to_s.count(" ") < 3
        entry.author = entry.author.gsub(",", " and ")
      end

      # Fix missing title
      entry.title = "No title" unless entry.title

      # Fix issue with uppercased DOI field in BibTeX not recognized downstream in citeproc (I think)
      entry.doi = entry.DOI if entry.respond_to? :doi and entry.doi.nil? and !entry.DOI.nil?

      super(entry.fields)
      self["type"] = entry.type

    # otherwise create the object from scratch based on ORCID metadata
    else
      logger.debug "Creating citation from ORCID metadata:\n" + work.ai
      type = WORK_TYPES.key(work["work-type"]) || :misc
      title = work["work-title"] ? work["work-title"]["title"]["value"] : "No title"
      super({:type => type,
      	     :title => title,
             :author => author})

      # Optional attributes
      self["journal"] = work["work-title"]["subtitle"]["value"] if work["work-title"] and work["work-title"]["subtitle"]
      self["year"] = work["publication-date"]["year"]["value"] if work["publication-date"]
    end

    # Some extra work may be needed to pick up the DOI
    if self.doi.nil? and work["work-external-identifiers"] and work["work-external-identifiers"]["work-external-identifier"] and work["work-external-identifiers"]["work-external-identifier"][0]["work-external-identifier-type"].upcase == "DOI"
      logger.debug "No DOI encountered yet, let's grab it from identifier metadata: " + work["work-external-identifiers"].ai
      doi = work["work-external-identifiers"]["work-external-identifier"][0]["work-external-identifier-id"]["value"]
      doi = doi.gsub(/(?i:DOI):?\s?(10\.\S+)/, '\1').strip
      logger.debug "Got a DOI from ORCID work identifier metadata: #{doi}"
      self["doi"] = doi
    end

    # Fix up the URL field if needed by adding a dx.doi.org URL
    if self.url.nil? and !self.doi.nil? 
      logger.debug "Setting self.url to DOI URI: http://dx.doi.org/#{doi}"
      self["url"] = Addressable::URI.escape "http://dx.doi.org/#{doi}"
    end

    logger.debug "got final work obj = " + self.ai
  end

  def hash
    "#{unique_title}_#{year}".hash
  end

  def url
    self["url"]
  end

  def doi
    self["doi"]
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
