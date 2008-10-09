require File.dirname(__FILE__) + '/../test_api_helper'
require File.dirname(__FILE__) + '/../../vendor/plugins/shopify_app/lib/shopify_api.rb'

class WordPressControllerTest < ActionController::TestCase
  
  def setup
    ShopifyAPI::Blog.stubs(:comments_enabled?).returns(true)
    
    ShopifyAPI::Page.stubs(:save).returns(true)
        
    WordPressImport.any_instance.stubs(:save_data).returns(true)
        
    ShopifyAPI::Session.stubs(:create_permission_url).returns('login/finalize')
    ShopifyAPI::Session.stubs(:valid?).returns(true)
    ShopifyAPI::Session.stubs(:site).returns('localhost')
        
    get 'login/finalize'
    session['shopify'] = ShopifyAPI::Session.new("localhost")
    
    @import = imports(:word_press)
  end
     
   def test_should_redirect_to_login_if_no_session
     session['shopify'] = nil
     actions = [:index, :create, :new, :import]
     for action in actions
       get action
       
       assert_response :redirect
       assert_redirected_to :controller => 'login'
     end
   end   

   def test_index_should_go_to_new_if_session
     get :index

     assert_response :redirect
     assert_redirected_to :action => 'new'
   end   

   def test_create_should_succeed
     WordPressImport.any_instance.expects(:guess).times(1)
     
     assert_difference "WordPressImport.count", +1 do
       post :create, :import => { :source => fixture_file_upload('../fixtures/files/word_press_import.xml', 'text/xml') }
     end
     
     assert_equal(File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press_import.xml').read, WordPressImport.find(:last).content)
   end

   def test_create_should_not_succeed_with_invalid_file_type
     assert_no_difference "WordPressImport.count" do
         post :create, :import => { :source => fixture_file_upload('../fixtures/files/postsxml.zip', 'text/xml') }
     end

     assert flash[:error]
     assert_template 'new'
   end
   
   def test_create_should_raise_exception_if_invalid_xml
     assert_difference "WordPressImport.count", +1 do
       post :create, :import => { :source => fixture_file_upload('../fixtures/files/word_press_import_typo.xml', 'text/xml') }
     end
     
    assert flash[:error]
    assert_template 'new'
  end
   
  def test_new_should_display_upload_form
    get :new

    assert_template 'new'
    assert_tag :form, :descendant => { :tag => 'input', :attributes => { :type => 'file' } }
  end
   
  def test_import_should_succeed_over_html
    post :import, :format => 'html'
    
    assert flash[:notice]
    assert_response :redirect
    assert_redirected_to :controller => 'dashboard', :action => 'index'
  end
  
  def test_import_failing_with_invalid_xml_over_html
    @bad_import = WordPressImport.last_import
    @bad_import.content = File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press_import_typo.xml').read
    @bad_import.save
    
    post :import, :format => 'html'

    assert_response :redirect
    assert_redirected_to :controller => 'dashboard', :action => 'index'
    assert flash[:error]
  end
  
  def test_import_should_succeed_over_js
    post :import, :format => 'js'
    
    assert flash[:notice]
    assert_response :ok
    assert_template '_import'
  end
  
  def test_import_failing_with_invalid_xml_over_js
    @bad_import = WordPressImport.last_import
    @bad_import.content = File.open(File.dirname(__FILE__) + '/../fixtures/files/word_press_import_typo.xml').read
    @bad_import.save
    
    post :import, :format => 'js'

    assert_response :ok
    assert_template '_import'
    assert flash[:error]
  end
end
