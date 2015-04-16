require 'spec_helper'
require 'fileutils'

describe 'Neo4jTest' do
  let(:test_directory) { 'tmp/test' }

  describe '::Server' do

  end

  describe '::Installer' do
    before(:each) do
      FileUtils.mkdir_p test_directory
    end

    after(:each) do
      FileUtils.remove_dir(test_directory) if File.exist? test_directory
    end

    describe '#file_name' do
      it 'return the correct filename for windows' do
        allow(OS::Underlying).to receive(:windows?) { true }

        expect(Neo4jTest::Installer.file_name).to eq 'neo4j.zip'
      end

      it 'returns the correct filename for unix' do
        allow(OS::Underlying).to receive(:windows?) { false }

        expect(Neo4jTest::Installer.file_name).to eq 'neo4j-unix.tar.gz'
      end
    end

    describe '#download_neo4j' do

      it 'downloads the correct file' do
        allow(Neo4jTest::Installer).to receive(:request_url).and_return('Test data')
        allow(Neo4jTest::Installer).to receive(:download_to).and_return(File.join(test_directory, 'test.txt'))

        Neo4jTest::Installer.download_neo4j 'community-2.2.0'
        expect(File.exist?('tmp/test')).to be true
      end
    end

    describe '#download_neo4j_unless_exists' do
      it 'downloads the correct file the first time' do
        allow(Neo4jTest::Installer).to receive(:request_url).and_return('Test data')
        allow(Neo4jTest::Installer).to receive(:download_to).and_return(File.join(test_directory, 'test.txt'))

        Neo4jTest::Installer.download_neo4j 'community-2.2.0'
        expect(File.exist?('tmp/test')).to be true
      end

      it 'doesnt download on subsequent tries' do
        allow(Neo4jTest::Installer).to receive(:request_url).and_return('Test data')
        allow(Neo4jTest::Installer).to receive(:download_to).and_return(File.join(test_directory, 'test.txt'))

        Neo4jTest::Installer.download_neo4j_unless_exists 'community-2.2.0'
        expect(File.exist?('tmp/test')).to be true

        expect(Neo4jTest::Installer).to_not receive(:download_neo4j)
        Neo4jTest::Installer.download_neo4j_unless_exists 'community-2.2.0'
        expect(File.exist?('tmp/test')).to be true
      end
    end
  end
end
