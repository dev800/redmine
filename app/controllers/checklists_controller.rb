# frozen_string_literal: true
class ChecklistsController < ApplicationController
  default_search_scope :checklist

  before_action :find_checklist, :only => [:show, :edit, :update]
  before_action :find_checklists, :only => [:destroy]
  before_action :find_optional_project, :only => [:index, :new, :create]
  before_action :authorize, :except => [:index, :show, :edit, :new, :create]
  before_action :find_issue, :only => [:new, :create]
  before_action :build_new_checklist_from_params, :only => [:new, :create]
  accept_rss_auth :index, :show
  accept_api_auth :index, :show, :create, :update, :destroy
  menu_item :checklists

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper_method :find_issue
  helper :issues
  helper :journals
  helper :projects
  helper :custom_fields
  helper :issue_relations
  helper :watchers
  helper :attachments
  helper :queries
  include QueriesHelper
  helper :repositories
  helper :timelog

  def index

  end

  def new
    @journals = @issue.visible_journals_with_index
    @project = @issue.project

    @allowed_statuses = @issue.new_statuses_allowed_to(User.current)
    @priorities = IssuePriority.active
    @time_entry = TimeEntry.new(:issue => @issue, :project => @issue.project)
    @time_entries = @issue.time_entries.visible.preload(:activity, :user)
    @relation = IssueRelation.new

    render :action => 'new', :layout => !request.xhr?
  end

  def create
    unless User.current.allowed_to?(:add_checklists, @checklist.project, :global => true)
      render :status => 403, :json => {
        :status => 403,
        :errors => {
          :messages => [],
          :full_messages => {}
        }
      } and return
    end

    call_hook(:controller_checklists_new_before_save, { :params => params, :checklist => @checklist })
    @checklist.save_attachments(params[:attachments] || (params[:checklist] && params[:checklist][:uploads]))

    if @checklist.save
      call_hook(:controller_checklists_new_after_save, { :params => params, :checklist => @checklist})

      render :json => {
        :status => "ok",
        :message => l("notice_successful_create")
      }
    else
      render status: 422, :json => {
        :status => 422,
        :errors => {
          messages: @checklist.errors.messages,
          full_messages: @checklist.errors.full_messages
        }
      }
    end
  end

  def show
    @journals = @checklist.visible_journals_with_index
  end

  def edit

  end

  def update

  end

  def destroy

  end

  protected

  # Used by #new and #create to build a new issue from the params
  # The new issue will be copied from an existing one if copy_from parameter is given
  def build_new_checklist_from_params
    @checklist = Checklist.new
    @checklist.issue = @issue
    @checklist.project = @project

    if request.get?
      @checklist.project ||= @checklist.allowed_target_projects.first
    end

    @checklist.author ||= User.current
    @checklist.start_date ||= User.current.today if Setting.default_issue_start_date_to_creation_date?

    attrs = (params[:checklist] || {}).deep_dup

    @checklist.tracker ||= @issue.allowed_target_trackers.first


    if action_name == 'new' && params[:was_default_status] == attrs[:status_id]
      attrs.delete(:status_id)
    end

    if action_name == 'new' && params[:form_update_triggered_by] == 'issue_project_id'
      attrs.delete(:fixed_version_id)
    end

    attrs[:assigned_to_id] = User.current.id if attrs[:assigned_to_id] == 'me'
    @checklist.safe_attributes = attrs

    if @checklist.project
      @checklist.tracker ||= @checklist.allowed_target_trackers.first

      if @checklist.tracker.nil?
        if @checklist.project.trackers.any?
          render :json => { :status => 403, :message => l(:error_no_tracker_allowed_for_new_checklist_in_project) }, :status => 403
        else
          render :json => { :status => 403, :message => l(:error_no_tracker_in_project) }, :status => 403
        end

        return false
      end

      if @checklist.status.nil?
        render :json => { :status => 403, :message => l(:error_no_default_issue_status) }, :status => 403
        return false
      end
    elsif request.get?
      render :json => { :status => 403, :message => l(:error_no_projects_with_tracker_allowed_for_new_checklist) }, :status => 403
      return false
    end

    @priorities = IssuePriority.active
    @allowed_statuses = @checklist.new_statuses_allowed_to(User.current)
  end

  def find_issue
    # Issue.visible.find(...) can not be used to redirect user to the login form
    # if the issue actually exists but requires authentication
    @issue = Issue.find(params[:issue_id])
    raise Unauthorized unless @issue.visible?
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
