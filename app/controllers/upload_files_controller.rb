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

class UploadFilesController < ApplicationController
  before_action :find_upload_file, :only => [:show, :download, :thumbnail, :update, :destroy]
  before_action :file_readable, :read_authorize, :only => [:show, :download, :thumbnail]
  before_action :update_authorize, :only => :update
  before_action :delete_authorize, :only => :destroy
  before_action :authorize_global, :only => :upload

  # Disable check for same origin requests for JS files, i.e. upload_files with
  # MIME type text/javascript.
  skip_after_action :verify_same_origin_request, :only => :download

  accept_api_auth :show, :download, :thumbnail, :upload, :update, :destroy

  def download
    @upload_file.increment_download

    if stale?(:etag => @upload_file.digest)
      # images are sent inline
      send_file @upload_file.diskfile, :filename => filename_for_content_disposition(@upload_file.filename),
                                      :type => detect_content_type(@upload_file),
                                      :disposition => disposition(@upload_file)
    end
  end

  def thumbnail
    if @upload_file.thumbnailable? && tbnail = @upload_file.thumbnail(:size => params[:size])
      if stale?(:etag => tbnail)
        send_file(
          tbnail,
          :filename => filename_for_content_disposition(@upload_file.filename),
          :type => detect_content_type(@upload_file, true),
          :disposition => 'inline')
      end
    else
      # No thumbnail for the upload_file or thumbnail could not be created
      head 404
    end
  end

  def upload
    upload_file = params[:uploadFile]

    @upload_file = UploadFile.new(:file => upload_file)
    @upload_file.author = User.current
    @upload_file.filename = upload_file.original_filename.presence || Redmine::Utils.random_hex(16)
    @upload_file.content_type = upload_file.content_type.presence
    saved = @upload_file.save
    @upload_file.move_to_target_directory!

    if saved
      render :json => {
        :error => 0,
        :url => upload_file_download_path(:id => @upload_file.id, :secret => @upload_file.secret),
        :filename => @upload_file.filename,
        :title => @upload_file.filename
      }
    else
      render :json => {:error => 1}
    end
  end

  private

  def find_upload_file
    @upload_file = UploadFile.find(params[:id])
    raise ActiveRecord::RecordNotFound if params[:secret] && params[:secret] != @upload_file.secret
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Checks that the file exists and is readable
  def file_readable
    if @upload_file.readable?
      true
    else
      logger.error "Cannot send upload_file, #{@upload_file.diskfile} does not exist or is unreadable."
      render_404
    end
  end

  def read_authorize
    @upload_file.visible? ? true : deny_access
  end

  def update_authorize
    @upload_file.editable? ? true : deny_access
  end

  def delete_authorize
    @upload_file.deletable? ? true : deny_access
  end

  def detect_content_type(upload_file, is_thumb = false)
    content_type = upload_file.content_type
    if content_type.blank? || content_type == "application/octet-stream"
      content_type =
        Redmine::MimeType.of(upload_file.filename).presence ||
        "application/octet-stream"
    end

    if is_thumb && content_type == "application/pdf"
      # PDF previews are stored in PNG format
      content_type = "image/png"
    end

    content_type
  end

  def disposition(upload_file)
    if upload_file.is_pdf?
      'inline'
    else
      'attachment'
    end
  end

  # Returns upload_files param for #update_all
  def update_all_params
    params.permit(:upload_files => [:filename, :description]).require(:upload_files)
  end
end
