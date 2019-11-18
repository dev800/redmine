# frozen_string_literal: true

# Redmine - project management software
# Copyright (C) 2006-2019  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

module Redmine
  module DefaultData
    class DataAlreadyLoaded < StandardError; end

    module Loader
      include Redmine::I18n

      class << self
        # Returns true if no data is already loaded in the database
        # otherwise false
        def no_data?
          !Role.where(:builtin => 0).exists? &&
            !Tracker.exists? &&
            !IssueStatus.exists? &&
            !Enumeration.exists?
        end

        # Loads the default data
        # Raises a RecordNotSaved exception if something goes wrong
        def load(lang=nil, options={})
          raise DataAlreadyLoaded.new("Some configuration data is already loaded.") unless no_data?
          set_language_if_valid(lang)
          workflow = !(options[:workflow] == false)

          Role.transaction do
            # Roles
            manager = Role.create! :name => l(:default_role_manager),
                                   :issues_visibility => 'all',
                                   :users_visibility => 'all',
                                   :position => 1
            manager.permissions = manager.setable_permissions.collect {|p| p.name}
            manager.save!

            developer = Role.create!(
                                     :name => l(:default_role_developer),
                                     :position => 2,
                                     :permissions => [:manage_versions,
                                                      :manage_categories,
                                                      :view_checklists,
                                                      :add_checklists,
                                                      :edit_checklists,
                                                      :edit_own_checklists,
                                                      :set_checklists_private,
                                                      :set_own_checklists_private,
                                                      :add_checklist_notes,
                                                      :edit_checklist_notes,
                                                      :edit_own_checklist_notes,
                                                      :delete_checklists,
                                                      :view_issues,
                                                      :add_issues,
                                                      :edit_issues,
                                                      :view_private_notes,
                                                      :set_notes_private,
                                                      :manage_issue_relations,
                                                      :manage_subtasks,
                                                      :add_issue_notes,
                                                      :save_queries,
                                                      :view_gantt,
                                                      :view_calendar,
                                                      :log_time,
                                                      :view_time_entries,
                                                      :view_news,
                                                      :comment_news,
                                                      :view_documents,
                                                      :add_documents,
                                                      :edit_documents,
                                                      :delete_documents,
                                                      :view_wiki_pages,
                                                      :view_wiki_edits,
                                                      :edit_wiki_pages,
                                                      :delete_wiki_pages,
                                                      :view_messages,
                                                      :add_messages,
                                                      :edit_own_messages,
                                                      :view_files,
                                                      :manage_files,
                                                      :browse_repository,
                                                      :view_changesets,
                                                      :commit_access,
                                                      :manage_related_issues])
            reporter = Role.create!(
                                   :name => l(:default_role_reporter),
                                   :position => 3,
                                   :permissions => [:view_issues,
                                                    :add_issues,
                                                    :add_issue_notes,
                                                    :view_checklists,
                                                    :add_checklists,
                                                    :edit_own_checklists,
                                                    :set_checklists_private,
                                                    :set_own_checklists_private,
                                                    :add_checklist_notes,
                                                    :edit_checklist_notes,
                                                    :edit_own_checklist_notes,
                                                    :delete_checklists,
                                                    :save_queries,
                                                    :view_gantt,
                                                    :view_calendar,
                                                    :log_time,
                                                    :view_time_entries,
                                                    :view_news,
                                                    :comment_news,
                                                    :view_documents,
                                                    :view_wiki_pages,
                                                    :view_wiki_edits,
                                                    :view_messages,
                                                    :add_messages,
                                                    :edit_own_messages,
                                                    :view_files,
                                                    :browse_repository,
                                                    :view_changesets])

            Role.non_member.update_attribute :permissions, [:view_issues,
                                                            :add_issues,
                                                            :add_issue_notes,
                                                            :view_checklists,
                                                            :add_checklists,
                                                            :save_queries,
                                                            :view_gantt,
                                                            :view_calendar,
                                                            :view_time_entries,
                                                            :view_news,
                                                            :comment_news,
                                                            :view_documents,
                                                            :view_wiki_pages,
                                                            :view_wiki_edits,
                                                            :view_messages,
                                                            :add_messages,
                                                            :view_files,
                                                            :browse_repository,
                                                            :view_changesets]

            Role.anonymous.update_attribute :permissions, [:view_issues,
                                                           :view_gantt,
                                                           :view_calendar,
                                                           :view_time_entries,
                                                           :view_news,
                                                           :view_documents,
                                                           :view_wiki_pages,
                                                           :view_wiki_edits,
                                                           :view_messages,
                                                           :view_files,
                                                           :browse_repository,
                                                           :view_changesets]

            # Issue statuses
            requirement = IssueStatus.create!(
              :name => l(:default_issue_status_requirement),
              :is_closed => false,
              :position => 1,
              :color => '000000',
              :background_color => 'ddeaf7',
              :flag_color => '03a9f4',
              :flag_value => 'requirement'
            )

            pending = IssueStatus.create!(
              :name => l(:default_issue_status_pending),
              :is_closed => false,
              :position => 2,
              :color => '000000',
              :background_color => 'f7e2d6',
              :flag_color => 'ff9800',
              :flag_value => 'pending'
            )

            rejected = IssueStatus.create!(
              :name => l(:default_issue_status_rejected),
              :is_closed => false,
              :position => 3,
              :color => '000000',
              :background_color => 'ffcca7',
              :flag_color => 'ff9800',
              :flag_value => 'rejected'
            )

            unsolved = IssueStatus.create!(
              :name => l(:default_issue_status_unsolved),
              :is_closed => false,
              :position => 4,
              :color => '000000',
              :background_color => 'ffeadc',
              :flag_color => 'ff9800',
              :flag_value => 'unsolved'
            )

            solving = IssueStatus.create!(
              :name => l(:default_issue_status_solving),
              :is_closed => false,
              :position => 5,
              :color => '000000',
              :background_color => 'e1efda',
              :flag_color => '4caf50',
              :flag_value => 'solving'
            )

            alpha = IssueStatus.create!(
              :name => l(:default_issue_status_alpha),
              :is_closed => false,
              :position => 6,
              :color => '000000',
              :background_color => 'ebf3e5',
              :flag_color => '4caf50',
              :flag_value => 'alpha'
            )

            bate = IssueStatus.create!(
              :name => l(:default_issue_status_bate),
              :is_closed => false,
              :position => 7,
              :color => '000000',
              :background_color => 'ecffde',
              :flag_color => '4caf50',
              :flag_value => 'bate'
            )

            qualified = IssueStatus.create!(
              :name => l(:default_issue_status_qualified),
              :is_closed => false,
              :position => 8,
              :color => '000000',
              :background_color => 'f3e4ff',
              :flag_color => '9c27b0',
              :flag_value => 'qualified'
            )

            released = IssueStatus.create!(
              :name => l(:default_issue_status_released),
              :is_closed => false,
              :position => 9,
              :color => '000000',
              :background_color => 'efd9ff',
              :flag_color => '9c27b0',
              :flag_value => 'released'
            )

            finished = IssueStatus.create!(
              :name => l(:default_issue_status_finished),
              :is_closed => true,
              :position => 10,
              :color => '000000',
              :background_color => 'e3ffd0',
              :flag_color => '009688',
              :flag_value => 'finished'
            )

            cancel = IssueStatus.create!(
              :name => l(:default_issue_status_cancel),
              :is_closed => true,
              :position => 11,
              :color => '000000',
              :background_color => 'e8e8e8',
              :flag_color => '9e9e9e',
              :flag_value => 'cancel'
            )

            # Trackers
            Tracker.create!(
              :name => l(:default_tracker_feature),
              :default_status_id => requirement.id,
              :is_in_chlog => true,
              :is_in_roadmap => true,
              :position => 1,
              :color => '8bc34a',
              :background_color => 'c6dfb4',
              :flag_color => 'c6dfb4',
              :flag_value => 'feature'
            )

            Tracker.create!(
              :name => l(:default_tracker_task),
              :default_status_id => pending.id,
              :is_in_chlog => true,
              :is_in_roadmap => true,
              :position => 2,
              :color => '03a9f4',
              :background_color => 'b4c6e7',
              :flag_color => 'b4c6e7',
              :flag_value => 'task'
            )

            Tracker.create!(
              :name => l(:default_tracker_support),
              :default_status_id => pending.id,
              :is_in_chlog => false,
              :is_in_roadmap => false,
              :position => 3,
              :color => '00bcd4',
              :background_color => '9bc2e6',
              :flag_color => '9bc2e6',
              :flag_value => 'support'
            )

            Tracker.create!(
              :name => l(:default_tracker_bug),
              :default_status_id => pending.id,
              :is_in_chlog => true,
              :is_in_roadmap => false,
              :position => 4,
              :color => 'ff5722',
              :background_color => 'ffc7ce',
              :flag_color => 'ffc7ce',
              :flag_value => 'bug'
            )

            Tracker.create!(
              :name => l(:default_tracker_checklist),
              :default_status_id => pending.id,
              :is_in_chlog => true,
              :is_in_roadmap => false,
              :position => 5,
              :color => 'ffc107',
              :background_color => 'ffeb9c',
              :flag_color => 'ffc107',
              :flag_value => 'checklist'
            )

            Tracker.create!(
              :name => l(:default_tracker_cases),
              :default_status_id => pending.id,
              :is_in_chlog => true,
              :is_in_roadmap => false,
              :position => 6,
              :color => '3dc506',
              :background_color => 'c6dfb4',
              :flag_color => 'c6dfb4',
              :flag_value => 'cases'
            )

            Tracker.create!(
              :name => l(:default_tracker_release),
              :default_status_id => pending.id,
              :is_in_chlog => true,
              :is_in_roadmap => false,
              :position => 7,
              :color => '9c27b0',
              :background_color => 'c49ee1',
              :flag_color => 'c49ee1',
              :flag_value => 'release'
            )

            # requirement, pending, rejected, unsolved, solving, alpha, bate, qualified, released, finished, cancel
            if workflow
              # Workflow
              Tracker.all.each { |t|
                IssueStatus.all.each { |os|
                  IssueStatus.all.each { |ns|
                    WorkflowTransition.create!(:tracker_id => t.id, :role_id => manager.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
                  }
                }
              }

              Tracker.all.each { |t|
                IssueStatus.all.each { |os|
                  IssueStatus.all.each { |ns|
                    WorkflowTransition.create!(:tracker_id => t.id, :role_id => developer.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
                  }
                }
              }

              Tracker.all.each { |t|
                IssueStatus.all.each { |os|
                  IssueStatus.all.each { |ns|
                    WorkflowTransition.create!(:tracker_id => t.id, :role_id => reporter.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
                  }
                }
              }
            end

            # Enumerations
            IssuePriority.create!(
              :name => l(:default_priority_low),
              :color => 'e6e8e8',
              :background_color => '97FFFF',
              :flag_color => '97FFFF',
              :flag_value => 'low',
              :position => 1
            )

            IssuePriority.create!(
              :name => l(:default_priority_normal),
              :color => '00CD66',
              :background_color => '43CD80',
              :flag_color => '43CD80',
              :flag_value => 'normal',
              :position => 2,
              :is_default => true
            )

            IssuePriority.create!(
              :name => l(:default_priority_high),
              :color => 'EEB422',
              :background_color => 'EEB422',
              :flag_color => 'EEB422',
              :flag_value => 'high',
              :position => 3
            )

            IssuePriority.create!(
              :name => l(:default_priority_urgent),
              :color => 'FA8072',
              :background_color => 'FA8072',
              :flag_color => 'FA8072',
              :flag_value => 'urgent',
              :position => 4
            )

            IssuePriority.create!(
              :name => l(:default_priority_immediate),
              :color => 'FF4500',
              :background_color => 'FF4500',
              :flag_color => 'FF4500',
              :flag_value => 'immediate',
              :position => 5
            )

            DocumentCategory.create!(:name => l(:default_doc_category_user), :position => 1, :flag_value => 'user')
            DocumentCategory.create!(:name => l(:default_doc_category_tech), :position => 2, :flag_value => 'tech')
            DocumentCategory.create!(:name => l(:default_doc_category_requirement), :position => 3, :flag_value => 'requirement')

            TimeEntryActivity.create!(:name => l(:default_activity_requirement), :position => 1, :flag_value => 'requirement')
            TimeEntryActivity.create!(:name => l(:default_activity_analysis), :position => 2, :flag_value => 'analysis')
            TimeEntryActivity.create!(:name => l(:default_activity_design), :position => 3, :flag_value => 'design')
            TimeEntryActivity.create!(:name => l(:default_activity_development), :position => 4, :flag_value => 'development')
            TimeEntryActivity.create!(:name => l(:default_activity_test), :position => 5, :flag_value => 'test')
            TimeEntryActivity.create!(:name => l(:default_activity_replease), :position => 6, :flag_value => 'replease')
            TimeEntryActivity.create!(:name => l(:default_activity_report), :position => 7, :flag_value => 'report')
            TimeEntryActivity.create!(:name => l(:default_activity_study), :position => 8, :flag_value => 'study')
            TimeEntryActivity.create!(:name => l(:default_activity_meeting), :position => 9, :flag_value => 'meeting')
          end
          true
        end
      end
    end
  end
end
