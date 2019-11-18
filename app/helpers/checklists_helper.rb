module ChecklistsHelper
  include ApplicationHelper

  class ChecklistFieldsRows
    include ActionView::Helpers::TagHelper

    def initialize
      @left = []
      @right = []
    end

    def left(*args)
      args.any? ? @left << cells(*args) : @left
    end

    def right(*args)
      args.any? ? @right << cells(*args) : @right
    end

    def size
      @left.size > @right.size ? @left.size : @right.size
    end

    def to_html
      content =
        content_tag('div', @left.reduce(&:+), :class => 'splitcontentleft') +
        content_tag('div', @right.reduce(&:+), :class => 'splitcontentleft')

      content_tag('div', content, :class => 'splitcontent')
    end

    def cells(label, text, options={})
      options[:class] = [options[:class] || "", 'attribute'].join(' ')
      content_tag 'div',
        content_tag('div', label + ":", :class => 'label') + content_tag('div', text, :class => 'value'),
        options
    end
  end

  def checklist_fields_rows
    r = ChecklistFieldsRows.new
    yield r
    r.to_html
  end

  def checklist_estimated_hours_details(checklist)
    if checklist.total_estimated_hours.present?
      if checklist.total_estimated_hours == checklist.estimated_hours
        l_hours_short(checklist.estimated_hours)
      else
        s = checklist.estimated_hours.present? ? l_hours_short(checklist.estimated_hours) : ""
        s += " (#{l(:label_total)}: #{l_hours_short(checklist.total_estimated_hours)})"
        s.html_safe
      end
    end
  end

  def checklist_spent_hours_details(checklist)
    if checklist.total_spent_hours > 0
      path = project_time_entries_path(checklist.project, :checklist_id => "~#{checklist.id}")

      if checklist.total_spent_hours == checklist.spent_hours
        link_to(l_hours_short(checklist.spent_hours), path)
      else
        s = checklist.spent_hours > 0 ? l_hours_short(checklist.spent_hours) : ""
        s += " (#{l(:label_total)}: #{link_to l_hours_short(checklist.total_spent_hours), path})"
        s.html_safe
      end
    end
  end

  def checklist_due_date_details(checklist)
    return if checklist&.due_date.nil?
    s = format_date(checklist.due_date)
    s += " (#{due_date_distance_in_words(checklist.due_date)})" unless checklist.closed?
    s
  end
end
