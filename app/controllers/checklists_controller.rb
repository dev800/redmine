# frozen_string_literal: true
class ChecklistsController < ApplicationController
  default_search_scope :checklist

  before_action :find_checklist, :only => [:show, :edit, :update]
  before_action :find_optional_issue, :only => [:index]
  before_action :find_optional_project, :only => [:index, :new, :create]
  before_action :find_issue, :only => [:new, :create]
  before_action :authorize, :except => [:index, :show, :edit, :new, :create, :sort, :participated]
  before_action :build_new_checklist_from_params, :only => [:new, :create]
  accept_rss_auth :index, :show
  accept_api_auth :index, :show, :create, :update, :destroy, :sort
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

  def participated
    @user = params[:checklists_user_id] ? User.find_by_id(params[:checklists_user_id]) : User.current

    @checklists = Checklist.participants_of_user(@user, {
      tracker: params[:checklists_tracker],
      status: params[:checklists_status],
      participants_type: params[:checklists_participants_type]
    }).includes([:project, :issue, :status, :tracker])

    render :action => 'participated', :layout => !request.xhr?
  end

  def index
    if params[:issue_id]
      find_issue()
      @project = @issue.project

      @checklists = @issue.queried_checklists(
        tracker: params[:checklists_tracker],
        status: params[:checklists_status]
      )
    else
      render_404
    end

  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def new
    @project = @issue.project
    @priorities = IssuePriority.active
    @allowed_statuses = IssueStatus.for_checklists_enable
    @checklist.importance = Issue::DEFAULT_IMPORTANCE

    render :action => 'new', :layout => !request.xhr?
  end

  def create
    unless @issue && @issue.checklistable?
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
    end
  end

  def show
    @journals = @checklist.visible_journals_with_index
  end

  def edit
    return unless update_checklist_from_params

    @project = @issue.project
    @priorities = IssuePriority.active
    @allowed_statuses = IssueStatus.for_checklists_enable

    render :action => 'edit', :layout => !request.xhr?
  end

  def update
    return unless update_checklist_from_params

    call_hook(:controller_checklists_edit_before_save, { :params => params, :checklist => @checklist })
    @checklist.save_attachments(params[:attachments] || (params[:checklist] && params[:checklist][:uploads]))

    Checklist.transaction do
      if params[:time_entry] &&
           (params[:time_entry][:hours].present? || params[:time_entry][:comments].present?) &&
           User.current.allowed_to?(:log_time, @issue.project)
        time_entry = @time_entry || TimeEntry.new
        time_entry.project = @issue.project
        time_entry.issue = @issue
        time_entry.checklist = @checklist
        time_entry.user ||= User.current
        time_entry.spent_on = User.current.today
        time_entry.safe_attributes = params[:time_entry]
        @issue.time_entries << time_entry
      end

      if @checklist.save
        call_hook(:controller_checklists_edit_after_save, { :params => params, :checklist => @checklist})
      else
        raise ActiveRecord::Rollback
      end
    end
  end

  def destroy
  end

  def sort
    params_checklists = (params[:checklists] || {}).values

    ids = params_checklists.map do |checklist|
      checklist['id'].to_i
    end

    checklists = Checklist.find(ids)
    checklist_positions = checklists.map(&:position).sort
    index = 0

    checklists.sort do |checklist1, checklist2|
      ids.index(checklist1.id) <=> ids.index(checklist2.id)
    end.map do |checklist|
      position = (checklist_positions[index] || checklist.position).to_i
      index += 1

      if position != checklist.position
        checklist.update_columns(position: position)
      end
    end
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

    checklist_attributes = (params[:checklist] || {}).deep_dup
    @checklist.tracker ||= @issue.allowed_target_trackers.first

    if action_name == 'new' && params[:was_default_status] == checklist_attributes[:status_id]
      checklist_attributes.delete(:status_id)
    end

    if action_name == 'new' && params[:form_update_triggered_by] == 'issue_project_id'
      checklist_attributes.delete(:fixed_version_id)
    end

    checklist_attributes[:assigned_to_id] = User.current.id if checklist_attributes[:assigned_to_id] == 'me'
    @checklist.safe_attributes = checklist_attributes

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
    @allowed_statuses = IssueStatus.for_checklists_enable
  end

  def update_checklist_from_params
    @time_entry = TimeEntry.new(:checklist => @checklist, :project => @checklist.project, :issue => @checklist.issue)

    if params[:time_entry]
      @time_entry.safe_attributes = params[:time_entry]
    end

    @checklist.init_journal(User.current)

    checklist_attributes = params[:checklist]
    checklist_attributes[:assigned_to_id] = User.current.id if checklist_attributes && checklist_attributes[:assigned_to_id] == 'me'

    if checklist_attributes && params[:conflict_resolution]
      case params[:conflict_resolution]
      when 'overwrite'
        checklist_attributes = checklist_attributes.dup
        checklist_attributes.delete(:lock_version)
      when 'add_notes'
        checklist_attributes = checklist_attributes.slice(:notes, :private_notes)
      when 'cancel'
        redirect_to checklist_path(@checklist)
        return false
      end
    end

    @checklist.safe_attributes = checklist_attributes
    @priorities = IssuePriority.active
    @allowed_statuses = IssueStatus.for_checklists_enable

    true
  end

  def find_issue
    # Issue.visible.find(...) can not be used to redirect user to the login form
    # if the issue actually exists but requires authentication
    @issue = Issue.find(params[:issue_id])
    raise Unauthorized unless @issue.visible?
    @project = @issue.project
    @issue
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
