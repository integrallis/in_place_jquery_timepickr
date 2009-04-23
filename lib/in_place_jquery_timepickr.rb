module InPlaceJQueryTimepickr
  module ViewHelper 
    # Example:
    #
    #   # View
    #   <%= in_place_timepickr :event, :start_time %>
    def in_place_timepickr(object, method, tag_options = {}, options = {})
      # object and method name as strings, since we allow symbols to be passed
      object_name = object.to_s
      method_name = method.to_s

      # get the target object
      @object = self.instance_variable_get("@#{object}") || options[:object]
      # resolve target format or use 24 hour format as default
      format = JS_TO_RUBY_FORMATS[options[:convention] || '24']
      # grab the display text
      current_val = @object.send(method_name) || Time.now
      display_text = h(options[:display_text] || current_val.strftime(format))

      # build the ui id to be updated
      id_string = "#{object_name}_#{method_name}_#{@object.id}_in_place_timepickr"
      # build the id for the input field
      input_field_id = "#{id_string}_field"
      # build the input field and the jquery timepickr javascript
      tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
      tag_options = { :id => input_field_id,
                      :value => display_text,
                      :class => "in_place_timepickr" }.merge!(tag_options)
      field = tag.to_input_field_tag("text", tag_options) +
              create_javascript_function(input_field_id, options)

      # result consists of the html to display value and hidden form containing
      # input field, ok, cancel and spinner animation
      ret = generate_html(id_string, display_text)
      ret << generate_form(id_string, object_name, method_name, field, @object, options)
    end

    # Example:
    #
    #   # View in a form f
    #   <%= f.timepickr :start_time %>
    module FormHelper
      def timepickr(object, method, tag_options = {}, options = {})
        # object and method name as strings, since we allow symbols to be passed
        object_name = object.to_s
        method_name = method.to_s

        # get the target object
        @object = self.instance_variable_get("@#{object}") || options[:object]
        # resolve target format or use 24 hour format as default
        format = JS_TO_RUBY_FORMATS[options[:convention] || '24']
        # grab the display text
        current_val = @object.send(method_name) || Time.now
        display_text = h(options[:display_text] || current_val.strftime(format))

        # build the ui id to be updated
        id_string = "#{object_name}_#{method_name}_#{@object.id}_timepickr"
        # build the id for the input field
        input_field_id = "#{id_string}_field"
        # build the input field and the jquery timepickr javascript
        tag = ::ActionView::Helpers::InstanceTag.new(object, method, self)
        tag_options = { :id => input_field_id,
                        :value => display_text,
                        :class => "in_place_timepickr" }.merge!(tag_options)
        tag.to_input_field_tag("text", tag_options) + create_javascript_function(input_field_id, options)
      end
    end

    protected

    # generates the html to display the value of the field formatted accordingly
    # it responds to the onclick event by hiding itself and showing the inplace edit
    # form
    def generate_html(id_string, display_text)
      content_tag(:span,
                  display_text,
                  :onclick => update_page do |page|
                                page.hide "#{id_string}"
                                page.show "#{id_string}_form"
                              end,
                  :onmouseover => visual_effect(:highlight, id_string),
                  :title => "Click to Edit",
                  :id => id_string,
                  :class => "inplace_span #{"empty_inplace" if display_text.blank?}"
      )
    end

    # generate an ajax form to post updates to the time portion of a model's property
    def generate_form(id_string, object_name, method_name, field, object, opts)
      retval = ""

      # the setter to be invoked on the controller
      set_method = opts[:action] || "set_#{object_name}_#{method_name}_time"
      # the text on the submit button
      save_button_text = opts[:save_button_text] || "OK"
      # the message displayed while posting
      loader_message = opts[:saving_text] || "Saving..."

      # create a remote form
      retval << form_remote_tag(
        :url => { :action => set_method, :id => object.id },
        :method => opts[:http_method] || :post,
        :loading => update_page do |page|
          page.show "loader_#{id_string}"
          page.hide "#{id_string}_form"
        end,
        :complete => update_page { |page| page.hide "loader_#{id_string}" },
        :html => {
          :class => "in_place_editor_form",
          :id => "#{id_string}_form",
          :style => "display:none"
        }
      )

      retval << field
      # add a hidden field with the format being used in the view
      retval << hidden_field_tag('convention', opts[:convention]) if opts[:convention]
      format = opts[:format_12] || opts[:format_24]
      retval << hidden_field_tag('format', format) if format
      retval << content_tag(:br) if opts[:br]
      # add the submit button
      retval << submit_tag( save_button_text, :class => "inplace_submit")
      # add the cancel link
      retval << link_to_function( "Cancel", update_page do |page|
        page.show "#{id_string}"
        page.hide "#{id_string}_form"
      end, {:class => "inplace_cancel" })
      retval << "</form>"
      # add the div for the loading spinner animation
      retval << content_tag(:div,
                            :id => "loader_#{id_string}",
                            :class => "inplace_loader",
                            :style => "display:none" ) do
        image_tag("spinner.gif") + "&nbsp;&nbsp;" + content_tag(:span, loader_message)
      end

      retval << content_tag(:br)
    end

    # translation hash for option symbols to jquery timepickr JS options
    RB_TO_JS_OPTIONS = {
      :convention => 'convention',
      :dropslide => 'dropslide',
      :format_12 => 'format12',
      :format_24 => 'format24',
      :handle => 'handle',
      :hours => 'hours',
      :minutes => 'minutes',
      :seconds => 'seconds',
      :prefix => 'prefix',
      :sufix => 'suffix',
      :range_min => 'rangeMin',
      :range_sec => 'rangeSec',
      :update_live => 'updateLive',
      :reset_on_blur => 'resetOnBlur'
    }

    # creates the jquery timepickr javascript for the input field
    def create_javascript_function(id, options)
      js_options = {}
      options.each_pair do |key, value|
        js_options[RB_TO_JS_OPTIONS[key]] = %('#{value}') if RB_TO_JS_OPTIONS.has_key? key
      end

      javascript_tag(%[
        jQuery(function() {
          jQuery('##{id}').timepickr(#{options_for_javascript(js_options)});
          jQuery('.ui-dropslide ol:eq(0) li:first').mouseover();
        });
      ])
    end
  end

  module ControllerHelper
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Example:
    #
    #   # Controller
    #   class BlogController < ApplicationController
    #     in_place_timepickr_for :publish_at, :start_time
    #   end
    #
    module ClassMethods
      def in_place_timepickr_for(object, attribute, options = {})
        # define a setter only for the time portion of a field
        define_method("set_#{object}_#{attribute}_time") do
          # find the target object
          @item = object.to_s.camelize.constantize.find(params[:id])
          # build the ui id to be updated
          id_string = "#{object}_#{attribute}_#{@item.id}_in_place_timepickr"
          # default the highlight colors for the ajax callback
          highlight_endcolor = options[:highlight_endcolor] || "#ffffff"
          highlight_startcolor = options[:highlight_startcolor] || "#ffff99"

          # figure the format of the incoming time string
          format = JS_TO_RUBY_FORMATS[params['convention'] || '24']
          # parse the time
          time = Time.parse(params[object][attribute])
          # retrieve the original date value
          date = @item.send(attribute)
          # update the value with the original date and the new time
          @item.update_attribute(attribute, Time.utc(date.year, date.month, date.mday, time.hour, time.min))
          # grab the updated value to send it back to the UI
          updated_value = @item.send(attribute).strftime(format)
          updated_value = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" if updated_value.blank?

          # do the ajax thing
          render :update do |page|
            page.replace_html "#{id_string}", updated_value
            page.hide "#{id_string}_form"
            page.show "#{id_string}"
            page.visual_effect :highlight, "#{id_string}", :duration => 0.5, :endcolor => "#{highlight_endcolor}", :startcolor => "#{highlight_startcolor}"
          end
        end
      end
    end
  end

  # hash of jquery timepickr default formats to ruby strftime format string
  JS_TO_RUBY_FORMATS = {
    "12" => "%I:%M %p",
    "24" => "%H:%M"
  }
end

module ActionView
  module Helpers
    class FormBuilder
      def timepickr(method, tag_options = {}, options = {})
        @template.timepickr(@object_name, method, tag_options, options.merge(:object => @object))
      end
    end
  end
end

