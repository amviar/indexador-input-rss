module JavascriptHelper
  JS_ESCAPE_MAP = {
    '\\'    => '\\\\',
    '</'    => '<\/',
    "\r\n"  => '\n',
    "\n"    => '\n',
    "\r"    => '\n',
    '"'     => '\\"',
    "'"     => "\\'"
  }

  JS_ESCAPE_MAP["\342\200\250".force_encoding(Encoding::UTF_8).encode!] = '&#x2028;'
  JS_ESCAPE_MAP["\342\200\251".force_encoding(Encoding::UTF_8).encode!] = '&#x2029;'

  class << self
    def included(base)
      base.helpers do
        # From Ruby on Rails ActionView::Helpers::JavaScriptHelper


        # Escapes carriage returns and single and double quotes for JavaScript segments.
        #
        # Also available through the alias j(). This is particularly helpful in JavaScript
        # responses, like:
        #
        #   $('some_element').replaceWith('<%=j render 'some/element_template' %>');
        def escape_javascript(javascript)
          if javascript
            result = javascript.gsub(/(\\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'])/u) {|match| JS_ESCAPE_MAP[match] }
            javascript.html_safe? ? result.html_safe : result
          else
            ''
          end
        end
      end
    end
  end
end
