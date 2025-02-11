# SPDX-License-Identifier: Apache-2.0
#
# The OpenSearch Contributors require contributions made to
# this file be licensed under the Apache-2.0 license or a
# compatible open source license.
#
# Modifications Copyright OpenSearch Contributors. See
# GitHub history for details.
#
# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'spec_helper'

describe OpenSearch::DSL::Search::Aggregations::SignificantTerms do

  let(:search) do
    described_class.new
  end

  describe '#to_hash' do

    it 'can be converted to a hash' do
      expect(search.to_hash).to eq(significant_terms: {})
    end
  end

  context 'when options methods are called' do

    let(:search) do
      described_class.new(:foo)
    end

    describe '#field' do

      before do
        search.field('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:field]).to eq('bar')
      end
    end

    describe '#size' do

      before do
        search.size('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:size]).to eq('bar')
      end
    end

    describe '#shard_size' do

      before do
        search.shard_size('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:shard_size]).to eq('bar')
      end
    end

    describe '#min_doc_count' do

      before do
        search.min_doc_count('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:min_doc_count]).to eq('bar')
      end
    end

    describe '#shard_min_doc_count' do

      before do
        search.shard_min_doc_count('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:shard_min_doc_count]).to eq('bar')
      end
    end

    describe '#include' do

      before do
        search.include('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:include]).to eq('bar')
      end
    end

    describe '#exclude' do

      before do
        search.exclude('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:exclude]).to eq('bar')
      end
    end

    describe '#background_filter' do

      before do
        search.background_filter('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:background_filter]).to eq('bar')
      end
    end

    describe '#mutual_information' do

      before do
        search.mutual_information('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:mutual_information]).to eq('bar')
      end
    end

    describe '#chi_square' do

      before do
        search.chi_square('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:chi_square]).to eq('bar')
      end
    end

    describe '#gnd' do

      before do
        search.gnd('bar')
      end

      it 'applies the option' do
        expect(search.to_hash[:significant_terms][:foo][:gnd]).to eq('bar')
      end
    end
  end

  describe '#initialize' do

    context 'when a block is provided' do

      let(:search) do
        described_class.new do
          field 'bar'
        end
      end

      it 'executes the block' do
        expect(search.to_hash).to eq(significant_terms: { field: 'bar' })
      end
    end
  end
end
