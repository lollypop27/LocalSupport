require 'rails_helper'

describe ApplicationController, :type => :controller, :helpers => :controllers do
  it '#request_controller_is(white_listed)' do
    allow(controller).to receive_messages :white_listed => %w(a b c)
    allow(request).to receive_messages :params => { 'controller' => 'a' }
    expect(controller.request_controller_is(controller.white_listed)).to be true

    allow(request).to receive_messages :params => { 'controller' => 'd' }
    expect(controller.request_controller_is(controller.white_listed)).to be false
  end

  it '#request_verb_is_get?' do
    request.env['REQUEST_METHOD'] = 'GET'
    expect(controller.request_verb_is_get?).to be true

    request.env['REQUEST_METHOD'] = 'PUT'
    expect(controller.request_verb_is_get?).to be false
  end

  it '#store_location stores URLs only when conditions permit' do
    allow(request).to receive_messages :path => 'this/is/a/path'

    allow(controller).to receive_messages :request_controller_is => false
    allow(controller).to receive_messages :request_verb_is_get? => false
    controller.store_location
    expect(session[:previous_url]).to be_nil

    allow(controller).to receive_messages :request_controller_is => true
    controller.store_location
    expect(session[:previous_url]).to be_nil

    allow(controller).to receive_messages :request_verb_is_get? => true
    controller.store_location
    expect(session[:previous_url]).to eq request.path
  end

  describe '#after_sign_in_path_for' do
    let(:user) {make_current_user_nonadmin}
    context 'user not associated with any org' do
      it 'should redirect to root' do
        allow(user).to receive_messages :organisation => nil, :pending_organisation_id => nil
        expect(controller.after_sign_in_path_for(user)).to eq '/'
      end
    end

    context 'user is org owner no previous url' do
      it 'should redirect to root' do
        allow(user).to receive_messages :organisation => mock_model(Organisation, id: 1, not_updated_recently?: true)
        expect(controller.after_sign_in_path_for(user)).to eq '/organisations/1'
      end
    end

    context 'user is org owner with previous url' do
      it 'should redirect to root' do
        allow(user).to receive_messages :organisation => mock_model(Organisation, id: 1, not_updated_recently?: true)
        session[:previous_url] = 'i/was/here'
        expect(controller.after_sign_in_path_for(user)).to eq '/organisations/1'
      end
    end
  end

  it '#after_accept_path_for' do
    user = make_current_user_nonadmin
    allow(user).to receive_messages :organisation => nil

    expect(controller.after_accept_path_for(user)).to eq '/'

    allow(user).to receive_messages :organisation => '1'
    expect(controller.after_accept_path_for(user)).to eq '/organisations/1'
  end

  describe 'allow_cookie_policy' do
    #before :each do
    #  request.should_receive(:referer).and_return "/hello"
    #end
    it 'cookie is set and redirected to referer' do
      expect(request).to receive(:referer).and_return "/hello"
      expect(response).to receive(:set_cookie)
      get :allow_cookie_policy
      expect(response).to redirect_to "/hello"
    end

    it 'redirects to root if request referer is nil' do
      expect(request).to receive(:referer).and_return nil
      expect(response).to receive(:set_cookie)
      get :allow_cookie_policy
      expect(response).to redirect_to '/'
    end

    it 'cookie has correct key/value pair' do
      expect(request).to receive(:referer).and_return "/hello"
      get :allow_cookie_policy
      expect(response.cookies).to eq({"cookie_policy_accepted"=>"true"})
    end
  end

  describe '#assign_footer_page_links' do
    it 'calls the model method that provides visible page links' do
      expect(Page).to receive(:visible_links).and_return(nil)
      subject.send(:assign_footer_page_links)  
    end
    it 'makes the visible page links available to the view' do
      fake_links = Object.new
      allow(Page).to receive(:visible_links).and_return(fake_links)
      subject.send(:assign_footer_page_links)  
      expect(assigns(:footer_page_links)).to be fake_links
    end
  end

  describe 'PRIVATE METHODS' do
    let(:user) { double :user }
    before { allow(controller).to receive_messages current_user: user }

    context '#authorize' do
      it 'Unauthorized: redirects to root_path and displays flash' do
        allow(controller).to receive_messages admin?: false
        expect(controller).to receive(:redirect_to).with(root_path) { true } # calling original raises errors
        expect(controller.flash).to receive(:[]=)
          .with(:error, 'You must be signed in as an admin to perform this action!')
          .and_call_original
        expect(controller.instance_eval { authorize }).to be false
        # can't assert `redirect_to root_path`: http://owowthathurts.blogspot.com/2013/08/rspec-response-delegation-error-fix.html
        expect(flash[:error]).not_to be_nil
      end

      it 'Authorized: allows execution to continue' do
        allow(controller).to receive_messages admin?: true
        expect(controller.instance_eval { authorize }).to be nil
      end
    end

    context '#admin?' do
      it 'returns nil when current_user is nil' do
        allow(controller).to receive_messages current_user: nil
        expect(controller.instance_eval { admin? }).to be_nil
      end

      it 'otherwise depends on { current_user.admin? }' do
        expect(user).to receive(:admin?) { false }
        expect(controller.instance_eval { admin? }).to be false
        expect(user).to receive(:admin?) { true }
        expect(controller.instance_eval { admin? }).to be true
      end
    end
  end
end

# all child controllers should implement the ApplicationController's
# before_filter
describe OrganisationsController, :type => :controller do
  it 'assigns footer page links on a given request' do
    get :index
    expect(assigns(:footer_page_links)).not_to be nil
  end
end

