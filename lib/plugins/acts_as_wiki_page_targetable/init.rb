# frozen_string_literal: true

require File.dirname(__FILE__) + '/lib/acts_as_wiki_page_targetable'
ActiveRecord::Base.send(:include, Redmine::Acts::WikiPageTargetable)
