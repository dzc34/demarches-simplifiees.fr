include ActionDispatch::TestProcess

describe NewAdministrateur::AttestationTemplatesController, type: :controller do
  let!(:attestation_template) { create(:attestation_template) }
  let(:admin) { create(:administrateur) }
  let!(:procedure) { create :procedure, administrateur: admin, attestation_template: attestation_template }
  let(:logo) { fixture_file_upload('spec/fixtures/files/white.png', 'image/png') }
  let(:logo2) { fixture_file_upload('spec/fixtures/files/white.png', 'image/png') }
  let(:signature) { fixture_file_upload('spec/fixtures/files/black.png', 'image/png') }
  let(:signature2) { fixture_file_upload('spec/fixtures/files/black.png', 'image/png') }
  let(:interlaced_logo) { fixture_file_upload('spec/fixtures/files/interlaced-black.png', 'image/png') }
  let(:uninterlaced_logo) { fixture_file_upload('spec/fixtures/files/uninterlaced-black.png', 'image/png') }
  let(:invalid_logo) { fixture_file_upload('spec/fixtures/files/invalid_file_format.json', 'application/json') }

  before do
    sign_in(admin.user)
    Timecop.freeze(Time.zone.now)
  end

  after { Timecop.return }

  shared_examples 'rendering a PDF successfully' do
    render_views
    it 'renders a PDF' do
      expect(subject.status).to eq(200)
      expect(subject.media_type).to eq('application/pdf')
    end
  end

  describe 'GET #preview' do
    let(:attestation_params) do
      { title: 't', body: 'b', footer: 'f' }
    end

    before do
      get :preview,
        params: {
          procedure_id: procedure.id
        }
      procedure.reload
    end

    context 'if an attestation template exists on the procedure' do
      after { procedure.attestation_template.destroy }

      context 'with images' do
        let!(:attestation_template) do
          create(:attestation_template, attestation_params.merge(logo: logo, signature: signature))
        end

        it { expect(assigns(:attestation)).to include(attestation_params) }
        it { expect(assigns(:attestation)[:created_at]).to eq(Time.zone.now) }
        it { expect(assigns(:attestation)[:logo].download).to eq(logo2.read) }
        it { expect(assigns(:attestation)[:signature].download).to eq(signature2.read) }
        it_behaves_like 'rendering a PDF successfully'
      end

      context 'without images' do
        let!(:attestation_template) do
          create(:attestation_template, attestation_params)
        end

        it { expect(assigns(:attestation)).to include(attestation_params) }
        it { expect(assigns(:attestation)[:created_at]).to eq(Time.zone.now) }
        it { expect(assigns(:attestation)[:logo]).to eq(nil) }
        it { expect(assigns(:attestation)[:signature]).to eq(nil) }
        it_behaves_like 'rendering a PDF successfully'
      end
    end
  end

  describe 'GET #edit' do
    before { get :edit, params: { procedure_id: procedure.id } }

    context 'if an attestation template exists on the procedure' do
      it { expect(subject.status).to eq(200) }
      it { expect(assigns(:attestation_template)).to eq(attestation_template) }
    end

    context 'if an attestation template does not exist on the procedure' do
      let(:attestation_template) { nil }
      it { expect(subject.status).to eq(200) }
      it { expect(assigns(:attestation_template).id).to be_nil }
      it { expect(assigns(:attestation_template)).to be_an_instance_of(AttestationTemplate) }
    end
  end

  describe 'POST #create' do
    let(:attestation_template) { nil }
    let(:attestation_params) { { title: 't', body: 'b', footer: 'f', activated: true } }

    context 'nominal' do
      before do
        post :create,
          params: {
            procedure_id: procedure.id,
            attestation_template: attestation_params.merge(logo: logo, signature: signature)
          }
        procedure.reload
      end

      it { expect(procedure.attestation_template).to have_attributes(attestation_params) }
      it { expect(procedure.attestation_template.activated).to be true }
      it { expect(procedure.attestation_template.logo.download).to eq(logo2.read) }
      it { expect(procedure.attestation_template.signature.download).to eq(signature2.read) }
      it { expect(response).to redirect_to edit_admin_procedure_attestation_template_path(procedure) }
      it { expect(flash.notice).to eq("L'attestation a bien été sauvegardée") }

      after { procedure.attestation_template.destroy }
    end

    context 'when something wrong happens in the attestation template creation' do
      let(:invalid_footer) { 'f' * 200 }
      let(:attestation_params) { { title: 't', body: 'b', footer: invalid_footer, activated: true } }

      before do
        post :create,
          params: {
            procedure_id: procedure.id,
            attestation_template: attestation_params
          }
        procedure.reload
      end

      it { expect(response).to redirect_to edit_admin_procedure_attestation_template_path(procedure) }
      it { expect(flash.alert).to be_present }
      it { expect(procedure.attestation_template).to be nil }
    end
  end

  describe 'PATCH #update' do
    let(:attestation_params) { { title: 't', body: 'b', footer: 'f' } }
    let(:attestation_params_with_images) { attestation_params.merge(logo: logo, signature: signature) }

    context 'nominal' do
      before do
        patch :update,
          params: {
            procedure_id: procedure.id,
            attestation_template: attestation_params_with_images
          }
        procedure.reload
      end

      it { expect(procedure.attestation_template).to have_attributes(attestation_params) }
      it { expect(procedure.attestation_template.logo.download).to eq(logo2.read) }
      it { expect(procedure.attestation_template.signature.download).to eq(signature2.read) }
      it { expect(response).to redirect_to edit_admin_procedure_attestation_template_path(procedure) }
      it { expect(flash.notice).to eq("L'attestation a bien été modifiée") }

      after { procedure.attestation_template.destroy }
    end

    context 'when something wrong happens in the attestation template creation' do
      before do
        expect_any_instance_of(AttestationTemplate).to receive(:update).and_return(false)
        expect_any_instance_of(AttestationTemplate).to receive(:errors)
          .and_return(double(full_messages: ['nop']))

        patch :update,
          params: {
            procedure_id: procedure.id,
            attestation_template: attestation_params_with_images
          }
        procedure.reload
      end

      it { expect(response).to redirect_to edit_admin_procedure_attestation_template_path(procedure) }
      it { expect(flash.alert).to eq('nop') }
    end
  end
end
