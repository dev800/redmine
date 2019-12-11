class ParticipantsController < ApplicationController
  before_action :require_login, :find_partable, :only => [:edit, :update, :index, :complete]
  before_action :find_participants, :only => [:edit, :index, :complete]

  def edit
    render :action => 'edit', :layout => !request.xhr?
  end

  def complete
    @keywords = params[:q].to_s.strip
    @users = User.all.limit(500).active.visible.sorted.like(@keywords).to_a
    render :action => 'complete', :layout => !request.xhr?
  end

  # TODO: 增加权限控制
  def update
    Participant.update(@partable, {
      :roles => params[:role],
      :user_id => params[:user_id].to_i,
      :checked => params[:checked] == 'true'
    })
  end

  def index

  end

  protected

  def find_participants
    @participants = @partable.participants.includes([:user])
  end

  def find_partable
    @partable = find_objet_from_params

    unless @partable.present?
      render_404
    end
  end

  def find_objet_from_params
    klass = Object.const_get(params[:object_type].camelcase) rescue nil
    klass.find(params[:object_id])
  end
end
