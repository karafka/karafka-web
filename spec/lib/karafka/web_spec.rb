# frozen_string_literal: true

RSpec.describe_current do
  describe 'modules files existence' do
    let(:lib_location) { File.join(Karafka::Web.gem_root, 'lib', 'karafka', 'web', '**/**') }
    let(:candidates) { Dir[lib_location].to_a }

    it do
      failed = candidates.select do |path|
        next if path.include?('web/ui/views')
        next if path.include?('web/ui/pro/views')
        next if path.include?('web/ui/public')

        File.directory?(path) && !File.exist?("#{path}.rb")
      end

      expect(failed).to eq([])
    end
  end
end
