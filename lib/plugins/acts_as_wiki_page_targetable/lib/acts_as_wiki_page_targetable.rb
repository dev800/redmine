# frozen_string_literal: true

module Redmine
  module Acts
    module WikiPageTargetable
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def acts_as_wiki_page_targetable(options = {})
        end
      end

      module InstanceMethods
        def self.included(base)
          base.extend ClassMethods
        end

        module ClassMethods

        end
      end
    end
  end
end
