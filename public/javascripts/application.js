/* Redmine - project management software
   Copyright (C) 2006-2019  Jean-Philippe Lang */

/* Fix for CVE-2015-9251, to be removed with JQuery >= 3.0 */
$.ajaxPrefilter(function (s) {
  if (s.crossDomain) {
    s.contents.script = false;
  }
});

function checkAll (id, checked) {
  $('#' + id).find('input[type=checkbox]:enabled').prop('checked', checked);
}

function toggleCheckboxesBySelector (selector) {
  var all_checked = true;
  $(selector).each(function (index) {
    if (!$(this).is(':checked')) { all_checked = false; }
  });
  $(selector).prop('checked', !all_checked).trigger('change');
}

function showAndScrollTo (id, focus) {
  $('#' + id).show();
  if (focus !== null) {
    $('#' + focus).focus();
  }
  $('html, body').animate({ scrollTop: $('#' + id).offset().top }, 100);
}

function toggleRowGroup (el) {
  var tr = $(el).parents('tr').first();
  var n = tr.next();
  tr.toggleClass('open');
  $(el).toggleClass('icon-expended icon-collapsed');
  while (n.length && !n.hasClass('group')) {
    n.toggle();
    n = n.next('tr');
  }
}

function collapseAllRowGroups (el) {
  var tbody = $(el).parents('tbody').first();
  tbody.children('tr').each(function (index) {
    if ($(this).hasClass('group')) {
      $(this).removeClass('open');
      $(this).find('.expander').switchClass('icon-expended', 'icon-collapsed');
    } else {
      $(this).hide();
    }
  });
}

function expandAllRowGroups (el) {
  var tbody = $(el).parents('tbody').first();
  tbody.children('tr').each(function (index) {
    if ($(this).hasClass('group')) {
      $(this).addClass('open');
      $(this).find('.expander').switchClass('icon-collapsed', 'icon-expended');
    } else {
      $(this).show();
    }
  });
}

function toggleAllRowGroups (el) {
  var tr = $(el).parents('tr').first();
  if (tr.hasClass('open')) {
    collapseAllRowGroups(el);
  } else {
    expandAllRowGroups(el);
  }
}

function toggleFieldset (el) {
  var fieldset = $(el).parents('fieldset').first();
  fieldset.toggleClass('collapsed');
  fieldset.children('legend').toggleClass('icon-expended icon-collapsed');
  fieldset.children('div').toggle();
}

function hideFieldset (el) {
  var fieldset = $(el).parents('fieldset').first();
  fieldset.toggleClass('collapsed');
  fieldset.children('div').hide();
}

// columns selection
function moveOptions (theSelFrom, theSelTo) {
  $(theSelFrom).find('option:selected').detach().prop("selected", false).appendTo($(theSelTo));
}

function moveOptionUp (theSel) {
  $(theSel).find('option:selected').each(function () {
    $(this).prev(':not(:selected)').detach().insertAfter($(this));
  });
}

function moveOptionTop (theSel) {
  $(theSel).find('option:selected').detach().prependTo($(theSel));
}

function moveOptionDown (theSel) {
  $($(theSel).find('option:selected').get().reverse()).each(function () {
    $(this).next(':not(:selected)').detach().insertBefore($(this));
  });
}

function moveOptionBottom (theSel) {
  $(theSel).find('option:selected').detach().appendTo($(theSel));
}

function initFilters () {
  $('#add_filter_select').change(function () {
    addFilter($(this).val(), '', []);
  });
  $('#filters-table td.field input[type=checkbox]').each(function () {
    toggleFilter($(this).val());
  });
  $('#filters-table').on('click', 'td.field input[type=checkbox]', function () {
    toggleFilter($(this).val());
  });
  $('#filters-table').on('click', '.toggle-multiselect', function () {
    toggleMultiSelect($(this).siblings('select'))
    $(this).toggleClass('icon-toggle-plus icon-toggle-minus')
  });
  $('#filters-table').on('keypress', 'input[type=text]', function (e) {
    if (e.keyCode == 13) $(this).closest('form').submit();
  });
}

function addFilter (field, operator, values) {
  var fieldId = field.replace('.', '_');
  var tr = $('#tr_' + fieldId);

  var filterOptions = availableFilters[field];
  if (!filterOptions) return;

  if (filterOptions['remote'] && filterOptions['values'] == null) {
    $.getJSON(filtersUrl, { 'name': field }).done(function (data) {
      filterOptions['values'] = data;
      addFilter(field, operator, values);
    });
    return;
  }

  if (tr.length > 0) {
    tr.show();
  } else {
    buildFilterRow(field, operator, values);
  }
  $('#cb_' + fieldId).prop('checked', true);
  toggleFilter(field);
  $('#add_filter_select').val('').find('option').each(function () {
    if ($(this).attr('value') == field) {
      $(this).attr('disabled', true);
    }
  });
}

function buildFilterRow (field, operator, values) {
  var fieldId = field.replace('.', '_');
  var filterTable = $("#filters-table");
  var filterOptions = availableFilters[field];
  if (!filterOptions) return;
  var operators = operatorByType[filterOptions['type']];
  var filterValues = filterOptions['values'];
  var i, select;

  var tr = $('<tr class="filter">').attr('id', 'tr_' + fieldId).html(
    '<td class="field"><input checked="checked" id="cb_' + fieldId + '" name="f[]" value="' + field + '" type="checkbox"><label for="cb_' + fieldId + '"> ' + filterOptions['name'] + '</label></td>' +
    '<td class="operator"><select id="operators_' + fieldId + '" name="op[' + field + ']"></td>' +
    '<td class="values"></td>'
  );
  filterTable.append(tr);

  select = tr.find('td.operator select');
  for (i = 0; i < operators.length; i++) {
    var option = $('<option>').val(operators[i]).text(operatorLabels[operators[i]]);
    if (operators[i] == operator) { option.prop('selected', true); }
    select.append(option);
  }
  select.change(function () { toggleOperator(field); });

  switch (filterOptions['type']) {
    case "list":
    case "list_optional":
    case "list_status":
    case "list_subprojects":
      tr.find('td.values').append(
        '<span style="display:none;"><select class="value" id="values_' + fieldId + '_1" name="v[' + field + '][]"></select>' +
        ' <span class="toggle-multiselect icon-only icon-toggle-plus">&nbsp;</span></span>'
      );
      select = tr.find('td.values select');
      if (values.length > 1) { select.attr('multiple', true); }
      for (i = 0; i < filterValues.length; i++) {
        var filterValue = filterValues[i];
        var option = $('<option>');
        if ($.isArray(filterValue)) {
          option.val(filterValue[1]).text(filterValue[0]);
          if ($.inArray(filterValue[1], values) > -1) { option.prop('selected', true); }
          if (filterValue.length == 3) {
            var optgroup = select.find('optgroup').filter(function () { return $(this).attr('label') == filterValue[2] });
            if (!optgroup.length) { optgroup = $('<optgroup>').attr('label', filterValue[2]); }
            option = optgroup.append(option);
          }
        } else {
          option.val(filterValue).text(filterValue);
          if ($.inArray(filterValue, values) > -1) { option.prop('selected', true); }
        }
        select.append(option);
      }
      break;
    case "date":
    case "date_past":
      tr.find('td.values').append(
        '<span style="display:none;"><input type="date" name="v[' + field + '][]" id="values_' + fieldId + '_1" size="10" class="value date_value" /></span>' +
        ' <span style="display:none;"><input type="date" name="v[' + field + '][]" id="values_' + fieldId + '_2" size="10" class="value date_value" /></span>' +
        ' <span style="display:none;"><input type="text" name="v[' + field + '][]" id="values_' + fieldId + '" size="3" class="value" /> ' + labelDayPlural + '</span>'
      );
      $('#values_' + fieldId + '_1').val(values[0]).datepickerFallback(datepickerOptions);
      $('#values_' + fieldId + '_2').val(values[1]).datepickerFallback(datepickerOptions);
      $('#values_' + fieldId).val(values[0]);
      break;
    case "string":
    case "text":
      tr.find('td.values').append(
        '<span style="display:none;"><input type="text" name="v[' + field + '][]" id="values_' + fieldId + '" size="30" class="value" /></span>'
      );
      $('#values_' + fieldId).val(values[0]);
      break;
    case "relation":
      tr.find('td.values').append(
        '<span style="display:none;"><input type="text" name="v[' + field + '][]" id="values_' + fieldId + '" size="6" class="value" /></span>' +
        '<span style="display:none;"><select class="value" name="v[' + field + '][]" id="values_' + fieldId + '_1"></select></span>'
      );
      $('#values_' + fieldId).val(values[0]);
      select = tr.find('td.values select');
      for (i = 0; i < filterValues.length; i++) {
        var filterValue = filterValues[i];
        var option = $('<option>');
        option.val(filterValue[1]).text(filterValue[0]);
        if (values[0] == filterValue[1]) { option.prop('selected', true); }
        select.append(option);
      }
      break;
    case "integer":
    case "float":
    case "tree":
      tr.find('td.values').append(
        '<span style="display:none;"><input type="text" name="v[' + field + '][]" id="values_' + fieldId + '_1" size="14" class="value" /></span>' +
        ' <span style="display:none;"><input type="text" name="v[' + field + '][]" id="values_' + fieldId + '_2" size="14" class="value" /></span>'
      );
      $('#values_' + fieldId + '_1').val(values[0]);
      $('#values_' + fieldId + '_2').val(values[1]);
      break;
  }
}

function toggleFilter (field) {
  var fieldId = field.replace('.', '_');
  if ($('#cb_' + fieldId).is(':checked')) {
    $("#operators_" + fieldId).show().removeAttr('disabled');
    toggleOperator(field);
  } else {
    $("#operators_" + fieldId).hide().attr('disabled', true);
    enableValues(field, []);
  }
}

function enableValues (field, indexes) {
  var fieldId = field.replace('.', '_');
  $('#tr_' + fieldId + ' td.values .value').each(function (index) {
    if ($.inArray(index, indexes) >= 0) {
      $(this).removeAttr('disabled');
      $(this).parents('span').first().show();
    } else {
      $(this).val('');
      $(this).attr('disabled', true);
      $(this).parents('span').first().hide();
    }

    if ($(this).hasClass('group')) {
      $(this).addClass('open');
    } else {
      $(this).show();
    }
  });
}

function toggleOperator (field) {
  var fieldId = field.replace('.', '_');
  var operator = $("#operators_" + fieldId);
  switch (operator.val()) {
    case "!*":
    case "*":
    case "nd":
    case "t":
    case "ld":
    case "nw":
    case "w":
    case "lw":
    case "l2w":
    case "nm":
    case "m":
    case "lm":
    case "y":
    case "o":
    case "c":
    case "*o":
    case "!o":
      enableValues(field, []);
      break;
    case "><":
      enableValues(field, [0, 1]);
      break;
    case "<t+":
    case ">t+":
    case "><t+":
    case "t+":
    case ">t-":
    case "<t-":
    case "><t-":
    case "t-":
      enableValues(field, [2]);
      break;
    case "=p":
    case "=!p":
    case "!p":
      enableValues(field, [1]);
      break;
    default:
      enableValues(field, [0]);
      break;
  }
}

function toggleMultiSelect (el) {
  if (el.attr('multiple')) {
    el.removeAttr('multiple');
    el.attr('size', 1);
  } else {
    el.attr('multiple', true);
    if (el.children().length > 10)
      el.attr('size', 10);
    else
      el.attr('size', 4);
  }
}

function showTab(name, url) {
  $('#tab-content-' + name).parent().find('.tab-content').hide();
  $('#tab-content-' + name).show();
  $('#tab-' + name).closest('.tabs').find('a').removeClass('selected');
  $('#tab-' + name).addClass('selected');

  replaceInHistory(url)

  return false;
}

function showIssueHistory(journal, url) {
  tab_content = $('#tab-content-history');
  tab_content.parent().find('.tab-content').hide();
  tab_content.show();
  tab_content.parent().children('div.tabs').find('a').removeClass('selected');

  $('#tab-' + journal).addClass('selected');

  replaceInHistory(url)

  switch(journal) {
    case 'notes':
      tab_content.find('.journal:not(.has-notes)').hide();
      tab_content.find('.journal.has-notes').show();
      break;
    case 'properties':
      tab_content.find('.journal.has-notes').hide();
      tab_content.find('.journal:not(.has-notes)').show();
      break;
    default:
      tab_content.find('.journal').show();
  }

  return false;
}

function getRemoteTab(name, remote_url, url, load_always) {
  load_always = load_always || false;
  var tab_content = $('#tab-content-' + name);

  tab_content.parent().find('.tab-content').hide();
  tab_content.parent().children('div.tabs').find('a').removeClass('selected');
  $('#tab-' + name).addClass('selected');

  replaceInHistory(url);

  if (tab_content.children().length == 0 && load_always == false) {
    $.ajax({
      url: remote_url,
      type: 'get',
      success: function(data){
        tab_content.html(data)
      }
    });
  }

  tab_content.show();
  return false;
}

$(document).on('change', '#participated-issues .filter-trigger', function() {
  var $this = $(this);
  var $option = $this.find('option[value="' + $this.val() + '"]');
  var href = $option.attr("href");
  var dataHref = $option.attr("data-href");
  var userId = $("#participated-issues").attr("data-user-id");
  var params = {_t: (new Date()).valueOf()};

  if (userId) {
    params["issues_user_id"] = userId;
  }

  pushHistory(href)

  $.ajax({
    method: "GET",
    url: dataHref,
    data: params,
    headers: {
      "X-Request-URL": window.location.href
    }
  }).success(function(html) {
    $("#participated-issues").replaceWith(html);
    $("#participated-issues").attr("data-user-id", userId);
    showTooltip();
  })
})

$(document).on('change', '#participated-checklists .filter-trigger', function() {
  var $this = $(this);
  var $option = $this.find('option[value="' + $this.val() + '"]');
  var href = $option.attr("href");
  var dataHref = $option.attr("data-href");
  var userId = $("#participated-checklists").attr("data-user-id");
  var params = {_t: (new Date()).valueOf()};

  if (userId) {
    params["checklists_user_id"] = userId;
  }

  pushHistory(href)

  $.ajax({
    method: "GET",
    url: dataHref,
    data: params,
    headers: {
      "X-Request-URL": window.location.href
    }
  }).success(function(html) {
    $("#participated-checklists").replaceWith(html);
    $("#participated-checklists").attr("data-user-id", userId);
    showTooltip();
  })
})

$(document).on('change', '.checklists-filter .filter-trigger', function() {
  var $this = $(this);
  var $option = $this.find('option[value="' + $this.val() + '"]');
  var href = $option.attr("href");
  var dataHref = $option.attr("data-href");

  replaceInHistory(href)

  $.ajax({
    method: "GET",
    url: dataHref,
    data: {_t: (new Date()).valueOf()},
    headers: {
      "X-Request-URL": window.location.href
    }
  }).success(function(res) {
    showTooltip();
  })
})

//replaces current URL with the "href" attribute of the current link
//(only triggered if supported by browser)
function replaceInHistory(url) {
  if (url) {
    if ("replaceState" in window.history && url !== undefined) {
      window.history.replaceState(null, document.title, url);
    }
  }
}

function pushHistory(url) {
  if (url) {
    if ("pushState" in window.history) {
      window.history.pushState(null, document.title, url);
    }
  }
}

function moveTabRight(el) {
  var lis = $(el).parents('div.tabs').first().find('ul').children();
  var bw = $(el).parents('div.tabs-buttons').outerWidth(true);
  var tabsWidth = 0;
  var i = 0;
  lis.each(function() {
    if ($(this).is(':visible')) {
      tabsWidth += $(this).outerWidth(true);
    }
  });
  if (tabsWidth < $(el).parents('div.tabs').first().width() - bw) { return; }
  $(el).siblings('.tab-left').removeClass('disabled');
  while (i<lis.length && !lis.eq(i).is(':visible')) { i++; }
  var w = lis.eq(i).width();
  lis.eq(i).hide();
  if (tabsWidth - w < $(el).parents('div.tabs').first().width() - bw) {
    $(el).addClass('disabled');
  }
}

function moveTabLeft(el) {
  var lis = $(el).parents('div.tabs').first().find('ul').children();
  var i = 0;
  while (i < lis.length && !lis.eq(i).is(':visible')) { i++; }
  if (i > 0) {
    lis.eq(i-1).show();
    $(el).siblings('.tab-right').removeClass('disabled');
  }
  if (i <= 1) {
    $(el).addClass('disabled');
  }
}

function displayTabsButtons() {
  var lis;
  var tabsWidth;
  var el;
  var numHidden;
  $('div.tabs').each(function() {
    el = $(this);
    lis = el.find('ul').children();
    tabsWidth = 0;
    numHidden = 0;
    lis.each(function(){
      if ($(this).is(':visible')) {
        tabsWidth += $(this).outerWidth(true);
      } else {
        numHidden++;
      }
    });
    var bw = $(el).parents('div.tabs-buttons').outerWidth(true);
    if ((tabsWidth < el.width() - bw) && (lis.length === 0 || lis.first().is(':visible'))) {
      el.find('div.tabs-buttons').hide();
    } else {
      el.find('div.tabs-buttons').show().children('button.tab-left').toggleClass('disabled', numHidden == 0);
    }
  });
}

function setPredecessorFieldsVisibility() {
  var relationType = $('#relation_relation_type');
  if (relationType.val() == "precedes" || relationType.val() == "follows") {
    $('#predecessor_fields').show();
  } else {
    $('#predecessor_fields').hide();
  }
}

function showModal(id, width, title) {
  var el = $('#'+id).first();
  if (el.length === 0 || el.is(':visible')) {return;}
  if (!title) title = el.find('h3.title').text();
  // moves existing modals behind the transparent background
  $(".modal").css('zIndex',99);
  el.dialog({
    width: width,
    modal: true,
    resizable: false,
    dialogClass: 'modal',
    title: title
  }).on('dialogclose', function(){
    $(".modal").css('zIndex',101);
  });
  el.find("input[type=text], input[type=submit]").first().focus();
}

function hideModal(el) {
  var modal;
  if (el) {
    modal = $(el).parents('.ui-dialog-content');
  } else {
    modal = $('#ajax-modal');
  }
  modal.dialog("close");
}

function collapseScmEntry(id) {
  $('.'+id).each(function() {
    if ($(this).hasClass('open')) {
      collapseScmEntry($(this).attr('id'));
    }
    $(this).hide();
  });
  $('#'+id).removeClass('open');
}

function expandScmEntry(id) {
  $('.'+id).each(function() {
    $(this).show();
    if ($(this).hasClass('loaded') && !$(this).hasClass('collapsed')) {
      expandScmEntry($(this).attr('id'));
    }
  });
  $('#'+id).addClass('open');
}

function scmEntryClick(id, url) {
    var el = $('#'+id);
    if (el.hasClass('open')) {
        collapseScmEntry(id);
        el.find('.expander').switchClass('icon-expended', 'icon-collapsed');
        el.addClass('collapsed');
        return false;
    } else if (el.hasClass('loaded')) {
        expandScmEntry(id);
        el.find('.expander').switchClass('icon-collapsed', 'icon-expended');
        el.removeClass('collapsed');
        return false;
    }
    if (el.hasClass('loading')) {
        return false;
    }
    el.addClass('loading');
    $.ajax({
      url: url,
      success: function(data) {
        el.after(data);
        el.addClass('open').addClass('loaded').removeClass('loading');
        el.find('.expander').switchClass('icon-collapsed', 'icon-expended');
      }
    });
    return true;
}

function randomKey(size) {
  var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  var key = '';
  for (var i = 0; i < size; i++) {
    key += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return key;
}

function updateIssueFrom(url, el) {
  $('#all_attributes input, #all_attributes textarea, #all_attributes select').each(function(){
    $(this).data('valuebeforeupdate', $(this).val());
  });
  if (el) {
    $("#form_update_triggered_by").val($(el).attr('id'));
  }
  return $.ajax({
    url: url,
    type: 'post',
    data: $('#issue-form').serialize()
  });
}

function replaceIssueFormWith(html){
  var replacement = $(html);
  $('#all_attributes input, #all_attributes textarea, #all_attributes select').each(function(){
    var object_id = $(this).attr('id');
    if (object_id && $(this).data('valuebeforeupdate')!=$(this).val()) {
      replacement.find('#'+object_id).val($(this).val());
    }
  });
  $('#all_attributes').empty();
  $('#all_attributes').prepend(replacement);
}

function updateBulkEditFrom(url) {
  $.ajax({
    url: url,
    type: 'post',
    data: $('#bulk_edit_form').serialize()
  });
}

function observeAutocompleteField(fieldId, url, options) {
  $(document).ready(function() {
    $('#'+fieldId).autocomplete($.extend({
      source: url,
      minLength: 2,
      position: {collision: "flipfit"},
      search: function(){$('#'+fieldId).addClass('ajax-loading');},
      response: function(){$('#'+fieldId).removeClass('ajax-loading');}
    }, options));
    $('#'+fieldId).addClass('autocomplete');
  });
}

function observeSearchfield(fieldId, targetId, url) {
  $('#'+fieldId).each(function() {
    var $this = $(this);
    $this.addClass('autocomplete');
    $this.attr('data-value-was', $this.val());
    var check = function() {
      var val = $this.val();
      if ($this.attr('data-value-was') != val){
        $this.attr('data-value-was', val);
        $.ajax({
          url: url,
          type: 'get',
          data: {q: $this.val()},
          success: function(data){ if(targetId) $('#'+targetId).html(data); },
          beforeSend: function(){ $this.addClass('ajax-loading'); },
          complete: function(){ $this.removeClass('ajax-loading'); }
        });
      }
    };
    var reset = function() {
      if (timer) {
        clearInterval(timer);
        timer = setInterval(check, 300);
      }
    };
    var timer = setInterval(check, 300);
    $this.bind('keyup click mousemove', reset);
  });
}

$(document).ready(function(){
  $(".drdn .autocomplete").val('');

  // This variable is used to focus selected project
  var selected;
  $(".drdn-trigger").click(function(e){
    var drdn = $(this).closest(".drdn");
    if (drdn.hasClass("expanded")) {
      drdn.removeClass("expanded");
    } else {
      $(".drdn").removeClass("expanded");
      drdn.addClass("expanded");
      selected = $('.drdn-items a.selected'); // Store selected project
      selected.focus(); // Calling focus to scroll to selected project
      if (!isMobile()) {
        drdn.find(".autocomplete").focus();
      }
      e.stopPropagation();
    }
  });
  $(document).click(function(e){
    if ($(e.target).closest(".drdn").length < 1) {
      $(".drdn.expanded").removeClass("expanded");
    }
  });

  observeSearchfield('projects-quick-search', null, $('#projects-quick-search').data('automcomplete-url'));

  $(".drdn-content").keydown(function(event){
    var items = $(this).find(".drdn-items");

    // If a project is selected set focused to selected only once
    if (selected && selected.length > 0) {
      var focused = selected;
      selected = undefined;
    }
    else {
      var focused = items.find("a:focus");
    }
    switch (event.which) {
    case 40: //down
      if (focused.length > 0) {
        focused.nextAll("a").first().focus();;
      } else {
        items.find("a").first().focus();;
      }
      event.preventDefault();
      break;
    case 38: //up
      if (focused.length > 0) {
        var prev = focused.prevAll("a");
        if (prev.length > 0) {
          prev.first().focus();
        } else {
          $(this).find(".autocomplete").focus();
        }
        event.preventDefault();
      }
      break;
    case 35: //end
      if (focused.length > 0) {
        focused.nextAll("a").last().focus();
        event.preventDefault();
      }
      break;
    case 36: //home
      if (focused.length > 0) {
        focused.prevAll("a").last().focus();
        event.preventDefault();
      }
      break;
    }
  });
});

function beforeShowDatePicker(input, inst) {
  var default_date = null;
  switch ($(input).attr("id")) {
    case "issue_start_date" :
      if ($("#issue_due_date").size() > 0) {
        default_date = $("#issue_due_date").val();
      }
      break;
    case "issue_due_date" :
      if ($("#issue_start_date").size() > 0) {
        var start_date = $("#issue_start_date").val();
        if (start_date != "") {
          start_date = new Date(Date.parse(start_date));
          if (start_date > new Date()) {
            default_date = $("#issue_start_date").val();
          }
        }
      }
      break;
  }
  $(input).datepickerFallback("option", "defaultDate", default_date);
}

(function($){
  $.fn.positionedItems = function(sortableOptions, options){
    var settings = $.extend({
      firstPosition: 1
    }, options );

    return this.sortable($.extend({
      axis: 'y',
      handle: ".sort-handle",
      helper: function(event, ui){
        ui.children('td').each(function(){
          $(this).width($(this).width());
        });
        return ui;
      },
      update: function(event, ui) {
        var sortable = $(this);
        var handle = ui.item.find(".sort-handle").addClass("ajax-loading");
        var url = handle.data("reorder-url");
        var param = handle.data("reorder-param");
        var data = {};
        data[param] = {position: ui.item.index() + settings['firstPosition']};
        $.ajax({
          url: url,
          type: 'put',
          dataType: 'script',
          data: data,
          error: function(jqXHR, textStatus, errorThrown){
            alert(jqXHR.status);
            sortable.sortable("cancel");
          },
          complete: function(jqXHR, textStatus, errorThrown){
            handle.removeClass("ajax-loading");
          }
        });
      },
    }, sortableOptions));
  }
}( jQuery ));

var warnLeavingUnsavedMessage;
function warnLeavingUnsaved(message) {
  warnLeavingUnsavedMessage = message;
  $(document).on('submit', 'form', function(){
    $('textarea').removeData('changed');
  });
  $(document).on('change', 'textarea', function(){
    $(this).data('changed', 'changed');
  });
  window.onbeforeunload = function(){
    var warn = false;
    $('textarea').blur().each(function(){
      if ($(this).data('changed')) {
        warn = true;
      }
    });
    if (warn) {return warnLeavingUnsavedMessage;}
  };
}

function setupAjaxIndicator() {
  $(document).bind('ajaxSend', function(event, xhr, settings) {
    if ($('.ajax-loading').length === 0 && settings.contentType != 'application/octet-stream') {
      $('#ajax-indicator').show();
    }
  });
  $(document).bind('ajaxStop', function() {
    $('#ajax-indicator').hide();
  });
}

function setupTabs() {
  if($('.tabs').length > 0) {
    displayTabsButtons();
    $(window).resize(displayTabsButtons);
  }
}

function setupFilePreviewNavigation() {
  // only bind arrow keys when preview navigation is present
  const element = $('.pagination.filepreview').first();
  if (element) {

    const handleArrowKey = function(selector, e){
      const href = $(element).find(selector).attr('href');
      if (href) {
        window.location = href;
        e.preventDefault();
      }
    };

    $(document).keydown(function(e) {
      if(e.shiftKey || e.metaKey || e.ctrlKey || e.altKey) return;
      switch(e.key) {
        case 'ArrowLeft':
          handleArrowKey('.previous a', e);
          break;

        case 'ArrowRight':
          handleArrowKey('.next a', e);
          break;
      }
    });
  }
}

function hideOnLoad() {
  $('.hol').hide();
}

function addFormObserversForDoubleSubmit() {
  $('form[method=post]').each(function() {
    if (!$(this).hasClass('multiple-submit')) {
      $(this).submit(function(form_submission) {
        if ($(form_submission.target).attr('data-submitted')) {
          form_submission.preventDefault();
        } else {
          $(form_submission.target).attr('data-submitted', true);
        }
      });
    }
  });
}

function defaultFocus(){
  if (($('#content :focus').length == 0) && (window.location.hash == '')) {
    var $input = $('#content input[type=text], #content textarea').first()

    if (!$input.hasClass('noneed-focused')) {
      $input.focus();
    }
  }
}

function blockEventPropagation(event) {
  event.stopPropagation();
  event.preventDefault();
}

function toggleDisabledOnChange() {
  var checked = $(this).is(':checked');
  $($(this).data('disables')).attr('disabled', checked);
  $($(this).data('enables')).attr('disabled', !checked);
  $($(this).data('shows')).toggle(checked);
}
function toggleDisabledInit() {
  $('input[data-disables], input[data-enables], input[data-shows]').each(toggleDisabledOnChange);
}

function toggleNewObjectDropdown() {
  var dropdown = $('#new-object + ul.menu-children');
  if(dropdown.hasClass('visible')){
    dropdown.removeClass('visible');
  }else{
    dropdown.addClass('visible');
  }
}

$(document).ready(function() {
  // https://jmblog.github.io/color-themes-for-google-code-prettify/
  prettyPrint();
})

$(document).on("change", '#issue_formatting_field select', function(e) {
  var $selector = $(this);
  var selectedValue = $selector.val();

  $("#issue_formatting_field").show();
  $("#issue_description_and_toolbar").show();

  if (selectedValue == 'richtext') {
    $("#issue_description_and_toolbar .jstTabs").hide();
    createRicheditor("#issue_description");
  } else {
    $("#issue_description_and_toolbar .jstTabs").show();

    removeRicheditor("#issue_description");
  }
})

function triggerIssueDescriptionEdit(trigger) {
  $(trigger).hide();
  $("#issue_formatting_field").show();
  $("#issue_description_and_toolbar").show();

  if ($('#issue_formatting_field select').val() == 'richtext') {
    $("#issue_description_and_toolbar .jstTabs").hide();
    createRicheditor("#issue_description");
  } else {
    $("#issue_description_and_toolbar .jstTabs").show();
  }
}

//	'source', '|', 'undo', 'redo', '|', 'preview', 'print', 'template', 'code', 'cut', 'copy', 'paste',
//	'plainpaste', 'wordpaste', '|', 'justifyleft', 'justifycenter', 'justifyright',
//	'justifyfull', 'insertorderedlist', 'insertunorderedlist', 'indent', 'outdent', 'subscript',
//	'superscript', 'clearhtml', 'quickformat', 'selectall', '|', 'fullscreen', '/',
//	'formatblock', 'fontname', 'fontsize', '|', 'forecolor', 'hilitecolor', 'bold',
//	'italic', 'underline', 'strikethrough', 'lineheight', 'removeformat', '|', 'image', 'multiimage',
//	'flash', 'media', 'insertfile', 'table', 'hr', 'emoticons', 'baidumap', 'pagebreak',
// 	'anchor', 'link', 'unlink', '|', 'about'
function removeRicheditor(selector) {
  KindEditor.remove(selector)
}

if (!window.kindEditor) {
  $(document).ready(function() {
    window.kindEditor = KindEditor.editor({
      allowFileManager: true,
      uploadJson: '/files/upload.json',
      themesPath: '/stylesheets/kindeditor/themes/',
      pluginsPath: '/javascripts/kindeditor/plugins/'
    });
  })
}

function createRicheditor(selector) {
  KindEditor.create(selector, {
    minHeight: 240,
    // pasteType: 0,
    uploadJson: '/files/upload.json',
    themesPath: '/stylesheets/kindeditor/themes/',
    pluginsPath: '/javascripts/kindeditor/plugins/',
    items: [
      'source', '|', 'undo', 'redo', '|', 'preview', 'code',
      'plainpaste', 'wordpaste', '|', 'justifyleft', 'justifycenter', 'justifyright',
      'justifyfull', 'insertorderedlist', 'insertunorderedlist', 'indent', 'outdent', 'subscript',
      'superscript', 'clearhtml', 'quickformat', 'selectall', '|', 'fullscreen', '/',
      'formatblock', 'fontname', 'fontsize', '|', 'forecolor', 'hilitecolor', 'bold',
      'italic', 'underline', 'strikethrough', 'lineheight', 'removeformat', 'image',
      'table', 'hr', 'emoticons', 'anchor', 'link', 'unlink'
    ]
  });
}

(function ( $ ) {
  // detect if native date input is supported
  var nativeDateInputSupported = true;

  var input = document.createElement('input');
  input.setAttribute('type','date');
  if (input.type === 'text') {
    nativeDateInputSupported = false;
  }

  var notADateValue = 'not-a-date';
  input.setAttribute('value', notADateValue);
  if (input.value === notADateValue) {
    nativeDateInputSupported = false;
  }

  $.fn.datepickerFallback = function( options ) {
    if (nativeDateInputSupported) {
      return this;
    } else {
      return this.datepicker( options );
    }
  };
}( jQuery ));

$(document).ready(function(){
  $(document).on('change', '#content input[data-disables], input[data-enables], input[data-shows]', toggleDisabledOnChange);
  toggleDisabledInit();

  $(document).on('click', '#history .tabs a', function(e){
    var tab = $(e.target).attr('id').replace('tab-','');
    document.cookie = 'history_last_tab=' + tab
  });
});

$(document).ready(function(){
  $(document).on('click', '#content div.jstTabs a.tab-preview', function(event) {
    var tab = $(event.target);

    var url = tab.data('url');
    var form = tab.parents('form');
    var jstBlock = tab.parents('.jstBlock');

    var element = encodeURIComponent(jstBlock.find('.wiki-edit').val());
    var attachments = form.find('.attachments_fields input').serialize();

    $.ajax({
      url: url,
      type: 'post',
      data: "text=" + element + '&' + attachments,
      success: function(data){
        jstBlock.find('.wiki-preview').html(data);
      }
    });
  });
});

function keepAnchorOnSignIn(form){
  var hash = decodeURIComponent(self.document.location.hash);
  if (hash) {
    if (hash.indexOf("#") === -1) {
      hash = "#" + hash;
    }
    form.action = form.action + hash;
  }
  return true;
}

$(function ($) {
  $('#auth_source_ldap_mode').change(function () {
    $('.ldaps_warning').toggle($(this).val() != 'ldaps_verify_peer');
  }).change();
});

function setFilecontentContainerHeight() {
  var $filecontainer = $('.filecontent-container');
  var fileTypeSelectors = ['.image', 'video'];

  if($filecontainer.length > 0 && $filecontainer.find(fileTypeSelectors.join(',')).length === 1) {
    var containerOffsetTop = $filecontainer.offset().top;
    var containerMarginBottom = parseInt($filecontainer.css('marginBottom'));
    var paginationHeight = $filecontainer.next('.pagination').height();
    var diff = containerOffsetTop + containerMarginBottom + paginationHeight;

    $filecontainer.css('height', 'calc(100vh - ' + diff + 'px)')
  }
}

function setupAttachmentDetail() {
  setFilecontentContainerHeight();
  $(window).resize(setFilecontentContainerHeight);
}

$(document).ready(function() {
  $("#content .toc").closest("#content").addClass("with-toc")

  if ($(window).scrollTop() > 100) {
    $("#goTop").show();
  } else {
    $("#goTop").hide();
  }

  $(function () {
    $(window).scroll(function() {
      if ($(window).scrollTop() > 100) {
        $("#goTop").fadeIn();
      } else {
        $("#goTop").fadeOut();
      }
    });

    $("#goTop").click(function() {
      $('body,html').animate({scrollTop: 0}, 500);
        return false;
    });
  });
});

function showTooltip() {
  $('[title]').tooltip({
      show: {
        delay: 400
      },
      position: {
        my: "center bottom-5",
        at: "center top"
      }
  });
}

$(function () {
  showTooltip();
});

function inlineAutoComplete(element) {
    'use strict';
    // do not attach if Tribute is already initialized
    if (element.dataset.tribute === 'true') {return;}

    const issuesUrl = element.dataset.issuesUrl;
    const usersUrl = element.dataset.usersUrl;

    const remoteSearch = function(url, cb) {
      const xhr = new XMLHttpRequest();
      xhr.onreadystatechange = function ()
      {
        if (xhr.readyState === 4) {
          if (xhr.status === 200) {
            var data = JSON.parse(xhr.responseText);
            cb(data);
          } else if (xhr.status === 403) {
            cb([]);
          }
        }
      };
      xhr.open("GET", url, true);
      xhr.send();
    };

    const tribute = new Tribute({
      trigger: '#',
      values: function (text, cb) {
        if (event.target.type === 'text' && $(element).attr('autocomplete') != 'off') {
          $(element).attr('autocomplete', 'off');
        }
        remoteSearch(issuesUrl + text, function (issues) {
          return cb(issues);
        });
      },
      lookup: 'label',
      fillAttr: 'label',
      requireLeadingSpace: true,
      selectTemplate: function (issue) {
        return '#' + issue.original.id;
      }
    });

    tribute.attach(element);
}

$(document).ready(setupAjaxIndicator);
$(document).ready(hideOnLoad);
$(document).ready(addFormObserversForDoubleSubmit);
$(document).ready(defaultFocus);
$(document).ready(setupAttachmentDetail);
$(document).ready(setupTabs);
$(document).ready(setupFilePreviewNavigation);
// $(document).on('focus', '[data-auto-complete=true]', function(event) {
//   inlineAutoComplete(event.target);
// });

// Begin happy add /////////////////////////////////////////
function escapeHTML(html) {
  if (html) {
    return html.replace(/&/g, '&amp;')
      .replace(/>/g, '&gt;')
      .replace(/</g, '&lt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;')
  } else {
    return html;
  }
}

function alert(msg, opts) {
  var opts = opts || {};

  $('#ajax-modal').html(
    '<h3 class="title">' + escapeHTML(opts.title || 'alert') + '</h3>' +
    '<div class="content">' + escapeHTML(msg) + '</div>'
  );

  showModal('ajax-modal');
}

function showHTMLDialog(html) {
  var $modal = $('#dialog-modal');
  $modal.html(html);
  $modal.find('.close').show();
  $("#dialog-overlay").show();
  $("#dialog-modal-wrapper").show();
  $('body').addClass('modal-overflow-hidden');
  $modal.find('input[type=text], textarea').first().focus();
}

function closeHTMLDialog() {
  $('#dialog-modal-wrapper').hide();
  $('#dialog-overlay').hide();
  $('body').removeClass('modal-overflow-hidden');
  $('#dialog-modal-wrapper textarea').removeData('changed');
}

function showErrorMessages(fullMessages, opts) {
  var opts = opts || {};
  alert(fullMessages.join("\n"), {title: opts.title || 'Error'});
}

$(document).on('ajax:success', 'form.with-indicator', function(event) {
  $('#ajax-indicator').show();
}).on('ajax:success', 'form.with-indicator', function(event) {
  $('#ajax-indicator').hide();
}).on('ajax:error', 'form.with-indicator', function(event) {
  $('#ajax-indicator').hide();
})

function imagePopup(image) {
  var $popupPanel = $(".image-popup-panel");

  if ($popupPanel.length === 0) {
    $("body").append('<div class="image-popup-panel"></div>');
    $popupPanel = $(".image-popup-panel");
  }

  $popupPanel.html('<div class="image-popup-panel__inner"><img class="image-popup-panel__img" src="' + image.src + '"/></div>');

  $popupPanel.find(".image-popup-panel__img").load(function() {
    var $this = $(this);
    var height = $this.get(0).height;
    var padding = 12;
    var windowHeight = $(window).height();

    if (height + padding * 2 <= windowHeight) {
      $this.css("top", (windowHeight - height) / 2 + "px");
    }
  })
}

$(document).on('click', '[action-usage="target-document-new-and-add"]', function() {
  showHTMLDialog('<div>hello world</div>');
})

$(document).on('click', '[action-usage="target-document-add"]', function() {

})

$(document).on('click', '[action-usage="target-document-edit"]', function() {

})

$(document).on('click', '[action-usage="target-document-remove"]', function() {

})

$(document).on("click", ".image-popup-panel", function() {
  $(this).remove();
})

$(document).on("click", ".wiki img", function() {
  imagePopup({ src: $(this).attr("src") });
})

$(document).on('click', '#dialog-modal .close', function(event) {
  closeHTMLDialog();
});

$(document).on('click', '[remote-href]', function(event) {
  var $target = $(this);

  $.get($target.attr('remote-href'), {})
    .success(function(html) {
      showHTMLDialog(html)

      if ($("#dialog-modal").find(".form-actions").length > 0) {
        $("#dialog-modal").addClass("with-form-actions")
      }

      setupAttachmentEvents();
    })
    .fail(function(res) {
      $.Toast.showToast({
        title: 'request fail',
        duration: 800,
        icon: 'error',
        image: ''
      });
    }).complete(function() { })
});

$(document).on('input', '.autocomplete[data-url]', function() {
  var $input = $(this);
  var dataUrl = $input.attr('data-url');
  var objectType = $input.attr('object-type');
  var objectId = $input.attr('object-id');

  $.get(dataUrl, { q: $input.val().trim() }, function(html) {
    $('[partable-type="' + objectType + '"][partable-id="' + objectId + '"] .participants-editing').html(html);
  })
})

$(document).on("click", '.participants-editing .user-role input[type="checkbox"]', function() {
  var $checkbox = $(this);
  var $partable = $checkbox.closest('.participants-container[partable-type][partable-id]');
  var objectType = $partable.attr('partable-type');
  var objectId = $partable.attr('partable-id');
  var checked = $checkbox.is(":checked");
  var userId = $checkbox.attr('user-id');
  var role = $checkbox.attr('role');

  $.ajax({
    url: '/participants/update.js',
    dataType: 'script',
    data: {
      object_type: objectType,
      object_id: objectId,
      user_id: userId,
      role: role,
      checked: checked
    },
    method: 'put'
  }).success(function(resp) {

  })
})

function syncData() {
  $.each($("[data-sync-url]"), function() {
    $.ajax({
      method: "GET",
      url: $(this).attr('data-sync-url'),
      data: {_t: (new Date()).valueOf()},
      headers: {
        "X-Request-URL": window.location.href
      }
    }).success(function(res) {
      showTooltip();
    })
  })
}

function bindChecklistSortable() {
  $( ".checklists.ui-sortable" ).sortable({
    stop: function() {
      var $checklists = $(this).find(".checklist[data-checklist-id]");
      var paramsChecklists = [];

      $.each($checklists, function() {
        var $this = $(this);
        var id = parseInt($this.attr('data-checklist-id'))
        var position = parseInt($this.attr('data-checklist-position'))

        paramsChecklists.push({
          id: id,
          position: position
        })
      })

      $.post("/checklists/sort.js", {
        checklists: paramsChecklists
      })
    }
  });
}

function getParameterByName(name, url) {
  if (!url) url = window.location.href;
  name = name.replace(/[\[\]]/g, '\\$&');
  var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
      results = regex.exec(url);
  if (!results) return null;
  if (!results[2]) return '';
  return decodeURIComponent(results[2].replace(/\+/g, ' '));
}

function setHeaderClass() {
  if ($("#main-menu > ul").length === 0) {
    $("body").removeClass("has-main-menu");
  }
}

function loadParticipatedIssues() {
  if ($('#participated-issues[data-loaded="false"]').length > 0) {
    var userId = $("#participated-issues").attr("data-user-id");
    var params = {_t: (new Date()).valueOf()};
    var participantsType = getParameterByName("issues_participants_type");
    var issuesTracker = getParameterByName("issues_tracker");
    var issuesStatus = getParameterByName("issues_status");

    if (userId) {
      params["issues_user_id"] = userId;
    }

    if (participantsType) {
      params["issues_participants_type"] = participantsType;
    }

    if (issuesTracker) {
      params["issues_tracker"] = issuesTracker;
    }

    if (issuesStatus) {
      params["issues_status"] = issuesStatus;
    }

    $.ajax({
      method: "GET",
      url: "/issues/participated",
      data: params,
      headers: {
        "X-Request-URL": window.location.href
      }
    }).success(function(html) {
      $("#participated-issues").replaceWith(html);
      $("#participated-issues").attr("data-user-id", userId);
      showTooltip();
    })
  }
}

function loadParticipatedChecklists() {
  if ($('#participated-checklists[data-loaded="false"]').length > 0) {
    var userId = $("#participated-checklists").attr("data-user-id");
    var params = {_t: (new Date()).valueOf()};
    var participantsType = getParameterByName("checklists_participants_type");
    var checklistsTracker = getParameterByName("checklists_tracker");
    var checklistStatus = getParameterByName("checklists_issue");

    if (userId) {
      params["checklists_user_id"] = userId;
    }

    if (participantsType) {
      params["checklists_participants_type"] = participantsType;
    }

    if (checklistsTracker) {
      params["checklists_tracker"] = issuesTracker;
    }

    if (checklistStatus) {
      params["checklists_status"] = checklistStatus;
    }

    $.ajax({
      method: "GET",
      url: "/checklists/participated",
      data: params,
      headers: {
        "X-Request-URL": window.location.href
      }
    }).success(function(html) {
      $("#participated-checklists").replaceWith(html);
      $("#participated-checklists").attr("data-user-id", userId);
      showTooltip();
    })
  }
}

$(function() {
  syncData();
  bindChecklistSortable();
  loadParticipatedIssues();
  loadParticipatedChecklists();
  setHeaderClass();
})

$(document).on('click', '.ui-widget-overlay', function() {
  $(this).remove();
  $('.ui-dialog').remove();
});

+function($, window, document, undefined) {
  var container = '<div class="toast-wrap"></div>';
  var context = '<div class="toast-content"></div>';
  var wrapSelector = ".toast-wrap";
  var toastSelector = ".toast-content";
  var styles = '.toast-wrap{position:fixed;top:0;left:0;right:0;bottom:0;z-index:9999;margin:auto;background:rgba(0,0,0,.2);}.toast-content{position:absolute;top: 50%;left: 50%;-webkit-transform: translate(-50%,-50%);-moz-transform: translate(-50%,-50%);-ms-transform: translate(-50%,-50%);-o-transform: translate(-50%,-50%);transform: translate(-50%,-50%);padding: 10px;background:rgba(0,0,0,.7);color:#fff;-webkit-border-radius: 5px;-moz-border-radius: 5px;border-radius: 5px;max-width: 300px;min-width: 54px;text-align:center;cursor: default;-webkit-user-select: none;-moz-user-select: none;-ms-user-select: none;user-select: none;}.toast-img{display:block;max-width: 35px;max-height: 35px;margin: 0 auto 5px;}.success{display:block;width: 12px;height: 20px;border-right:6px solid #fff;border-bottom: 8px solid #fff;transform: rotate(45deg);-webkit-transform:rotate(45deg);margin: 0 auto 5px;}.error{display:block;width: 24px;height: 24px;font-size: 20px;color:rgba(255,255,255,.8);border:2px solid rgba(255,255,255,.8);border-radius: 50%;-webkit-border-radius: 50%;margin: 0 auto 5px;line-height:20px;text-align: center}.loading{position:relative;margin: 0 auto 5px;display:block;width:20px;height: 20px;border: 2px solid #fff;border-radius: 50%;-webkit-border-radius: 50%;animation: loading 1s linear infinite;}.loading:before{content: "";display: block;position: absolute;top: -5px;left: 0;width: 10px;height: 10px;background: #fff;border-radius: 50%; }@keyframes loading{0%{transform: rotate(0deg);}50%{transform: rotate(180deg);}100%{transform: rotate(360deg);}}@-webkit-keyframes loading{0%{-webkit-transform: rotate(0deg);}50%{-webkit-transform: rotate(180deg);}100%{-webkit-transform: rotate(360deg);}}';

  var Toast = {
    default : {
      "title": "loading...", // <String>提示的内容，默认："加载中..."
      "icon": "loading", // <String>图标，有效值 "success", "loading", "none", "error"，默认"loading"
      "image": "", // <String>自定义图标的本地路径，image 的优先级高于 icon
      "duration": 1500, // <Number>提示的延迟时间，单位毫秒，默认：1500(设置为0时不自动关闭)
    },
    showToast: function(opt){
      var _this = this;
      this.options = $.extend({}, this.default, opt);
      $("body").append(container);
      $(wrapSelector).append(context);
      $("<style></style>").text(styles).appendTo($(wrapSelector));
      if(this.options.image !== ""){
        $(toastSelector).append('<img src="'+this.options.image+'" class="toast-img" alt="toast...">');
      } else {
        $(toastSelector).append('<span class="toast-icon"></span>');
        switch(this.options.icon){
          case "success":
            $(".toast-icon").addClass('success');
            break;
          case "error":
            $(".toast-icon").addClass('error');
            $(".toast-icon").html("&times;");
            break;
          case "none":
            $(".toast-icon").remove();
            break;
          default:
            $(".toast-icon").addClass('loading');
            break;
        }
      }
      $(toastSelector).append('<p style="margin:0;"></p>').find('p').html(this.options.title);
      if(this.options.duration>0){
        setTimeout(function(){
          _this.hideToast();
        }, this.options.duration);
      }
    },
    hideToast: function(){
      if($(wrapSelector).length){
        $(wrapSelector).fadeOut(500);
        setTimeout(function(){
          $(wrapSelector).empty().remove()
        },1000);
      } else {
        return;
      }
    }
  };

  $.Toast = Toast;
}(jQuery, window, document);
