require "in_place_jquery_timepickr"

ActionController::Base.send :include, InPlaceJQueryTimepickr::ControllerHelper
ActionController::Base.helper InPlaceJQueryTimepickr::ViewHelper
ActionView::Helpers::FormHelper.send(:include, InPlaceJQueryTimepickr::ViewHelper::FormHelper)
ActionView::Base.send(:include, InPlaceJQueryTimepickr::ViewHelper::FormHelper)

ActionView::Helpers::AssetTagHelper.register_javascript_include_default "jquery"
ActionView::Helpers::AssetTagHelper.register_javascript_include_default "jquery.noconflict"

ActionView::Helpers::AssetTagHelper.register_javascript_expansion :in_place_jquery_timepickr => ["jquery.anchorHandler", "jquery.ui.all", "jquery.timepickr","jquery.timepickr"]
ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion :in_place_jquery_timepickr => ["jquery.timepickr"]