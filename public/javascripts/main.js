$(document).ready(function() {
  $('form[method="delete"]').on('submit', function(e) {
    e.preventDefault();
    jQuery.ajax({
      url: $(this).attr('action'),
      type: 'DELETE',
      dataType: 'json',
      data: {
        slug: $(this).children('input[name="feed[slug]"]').val()
      }
    });
  });
});
