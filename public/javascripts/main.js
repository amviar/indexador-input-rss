$(document).ready(function() {
  $('form[method="delete"]').on('submit', function(e) {
    e.preventDefault();
    jQuery.ajax({
      url: $(this).attr('action'),
      type: 'DELETE',
      dataType: 'script',
      data: {
        slug: $(this).children('input[name="feed[slug]"]').val()
      },
      success: function(resp) {
        eval(resp);
      }
    });
  });
});
