RSpec.describe Spree::Api::RelationsController, type: :controller do
  stub_authorization!
  render_views

  let(:user)     { create(:user) }
  let!(:product) { create(:product) }
  let!(:other1)  { create(:product) }

  let!(:relation_type) { create(:relation_type) }
  let!(:relation) { create(:relation, relatable: product, related_to: other1, relation_type: relation_type, position: 0) }

  before do
    user.generate_spree_api_key!
    allow(controller).to receive(:spree_current_user).and_return(user)
  end

  context 'model_class' do
    it 'responds to model_class as Spree::Relation' do
      expect(controller.send(:model_class)).to eq Spree::Relation
    end
  end

  describe 'with JSON' do
    let(:valid_params) do
      {
        format: :json,
        product_id: product.id,
        relation: {
          related_to_id: other1.id,
          relation_type_id: relation_type.id
        },
        token: user.spree_api_key
      }
    end

    context '#create' do
      it 'creates the relation' do
        expect {
          post :create, params: valid_params
        }.to change(Spree::Relation, :count).by(1)
      end

      it 'responds 422 error with invalid params' do
        params = {
          format: :json,
          product_id: product.id,
          token: user.spree_api_key
        }

        post :create, params: params
        expect(response.status).to eq(422)
      end
    end

    context '#update' do
      it 'succesfully updates the relation ' do
        params = { format: :json, product_id: product.id, id: relation.id, relation: { discount_amount: 2.0 }, token: user.spree_api_key }
        expect {
          put :update, params: params
        }.to change { relation.reload.discount_amount.to_s }.from('0.0').to('2.0')
      end
    end

    context '#destroy with' do
      it 'records successfully' do
        params = {
          id: relation.id,
          product_id: product.id,
          format: :json,
          token: user.spree_api_key
        }

        expect {
          delete :destroy, params: params
        }.to change(Spree::Relation, :count).by(-1)
      end
    end

    context '#update_positions' do
      it 'returns the correct position of the related products' do
        other2    = create(:product)
        relation2 = create(:relation, relatable: product, related_to: other2, relation_type: relation_type, position: 1)
        params = {
          product_id: product.id,
          id: relation.id,
          positions: {
            relation.id => '1',
            relation2.id => '0'
          },
          format: :json,
          token: user.spree_api_key
        }

        expect {
          post :update_positions, params: params
          relation.reload
        }.to change(relation, :position).from(0).to(1)
      end
    end
  end
end
