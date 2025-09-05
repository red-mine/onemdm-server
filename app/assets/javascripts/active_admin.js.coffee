#= require active_admin/base

# Dynamically load assignable group names for the batch action dialog.
populateAssignableGroups = ->
  dlg = $('.active_admin_dialog')
  return unless dlg.length
  # Identify that this dialog is for assign_group
  isAssign = false
  # Prefer checking hidden batch_action field if present
  hidden = dlg.find('input[name="batch_action"]').first()
  if hidden.length and hidden.val() == 'assign_group'
    isAssign = true
  else if /Select Group to assign/i.test(dlg.text())
    isAssign = true
  return unless isAssign

  select = dlg.find('select').first()
  return unless select.length

  ids = $('input.collection_selection:checked').map(-> @value).get()
  return unless ids.length > 0

  token = $('meta[name="csrf-token"]').attr('content')
  $.ajax
    url: '/admin/devices/assignable_group_names'
    method: 'POST'
    headers:
      'X-CSRF-Token': token
    data:
      ids: ids
    success: (resp) ->
      select.empty()
      if resp?.names?.length > 0
        for name in resp.names
          select.append($('<option>').val(name).text(name))
      else
        select.append($('<option disabled selected>').text('No assignable groups'))
    error: ->
      return

ready = ->
  # Click handler as primary trigger
  $(document).on 'click', 'a.batch_action', (e) ->
    setTimeout(populateAssignableGroups, 0)

  # MutationObserver as backup if click handler misses
  if window.MutationObserver?
    observer = new MutationObserver (mutations) ->
      for m in mutations when m.addedNodes?.length
        for n in m.addedNodes
          if n.nodeType == 1 and $(n).hasClass('active_admin_dialog')
            setTimeout(populateAssignableGroups, 0)
  
    observer.observe document.body, { childList: true }

$(document).on 'turbolinks:load', ready
$(ready)
