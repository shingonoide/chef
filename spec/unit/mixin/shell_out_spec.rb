#
# Author:: Ho-Sheng Hsiao (hosh@opscode.com)
# Code derived from spec/unit/mixin/command_spec.rb
#
# Original header:
# Author:: Hongli Lai (hongli@phusion.nl)
# Copyright:: Copyright (c) 2009 Phusion
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'

describe Chef::Mixin::ShellOut do
  include Chef::Mixin::ShellOut

  describe '#run_command_compatible_options' do
    subject { run_command_compatible_options(command_args) }
    let(:command_args) { [ cmd, options ] }
    let(:cmd) { "echo '#{rand(1000)}'" }

    let(:output) { StringIO.new }
    let!(:capture_log_output) { Chef::Log.logger = Logger.new(output)  }
    let(:assume_deprecation_log_level) { allow(Chef::Log).to receive(:level).and_return(:warn) }

    context 'without options' do
      let(:command_args) { [ cmd ] }

      it 'should not edit command args' do
        should eql(command_args)
      end
    end

    context 'without deprecated options' do
      let(:options) { { :environment => environment } }
      let(:environment) { { 'LC_ALL' => 'C' } }

      it 'should not edit command args' do
        should eql(command_args)
      end
    end

    def self.should_emit_deprecation_warning_about(old_option, new_option)
      it 'should emit a deprecation warning' do
        assume_deprecation_log_level and capture_log_output
        subject
        expect(output.string).to match /DEPRECATION:/
        expect(output.string).to match Regexp.escape(old_option.to_s)
        expect(output.string).to match Regexp.escape(new_option.to_s)
      end
    end

    context 'with :command_log_level option' do
      let(:options) { { :command_log_level => command_log_level } }
      let(:command_log_level) { :warn }

      it 'should convert :command_log_level to :log_level' do
        should eql [ cmd, { :log_level => command_log_level } ]
      end

      should_emit_deprecation_warning_about :command_log_level, :log_level
    end

    context 'with :command_log_prepend option' do
      let(:options) { { :command_log_prepend => command_log_prepend } }
      let(:command_log_prepend) { 'PROVIDER:' }

      it 'should convert :command_log_prepend to :log_tag' do
        should eql [ cmd, { :log_tag => command_log_prepend } ]
      end

      should_emit_deprecation_warning_about :command_log_prepend, :log_tag
    end

    context "with 'command_log_level' option" do
      let(:options) { { 'command_log_level' => command_log_level } }
      let(:command_log_level) { :warn }

      it "should convert 'command_log_level' to :log_level" do
        should eql [ cmd, { :log_level => command_log_level } ]
      end

      should_emit_deprecation_warning_about :command_log_level, :log_level
    end

    context "with 'command_log_prepend' option" do
      let(:options) { { 'command_log_prepend' => command_log_prepend } }
      let(:command_log_prepend) { 'PROVIDER:' }

      it "should convert 'command_log_prepend' to :log_tag" do
        should eql [ cmd, { :log_tag => command_log_prepend } ]
      end

      should_emit_deprecation_warning_about :command_log_prepend, :log_tag
    end
  end

  context "when testing individual methods" do
    before(:each) do
      @original_env = ENV.to_hash
      ENV.clear
    end

    after(:each) do
      ENV.clear
      ENV.update(@original_env)
    end

    let(:shell_out) { Chef::Mixin::ShellOut }
    let(:cmd) { "echo '#{rand(1000)}'" }

    describe "#shell_out" do

      describe "when the last argument is a Hash" do
        describe "and environment is an option" do
          it "should not change environment['LC_ALL'] when set to nil" do
            options = { :environment => { 'LC_ALL' => nil } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out(cmd, options)
          end

          it "should not change environment['LC_ALL'] when set to non-nil" do
            options = { :environment => { 'LC_ALL' => 'en_US.UTF-8' } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out(cmd, options)
          end

          it "should set environment['LC_ALL'] to 'en_US.UTF-8' when 'LC_ALL' not present" do
            options = { :environment => { 'HOME' => '/Users/morty' } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, {
              :environment => { 'HOME' => '/Users/morty', 'LC_ALL' => 'en_US.UTF-8' },
            }).and_return(true)
            shell_out.shell_out(cmd, options)
          end

          it "should not mutate the options hash when it adds LC_ALL" do
            options = { :environment => { 'HOME' => '/Users/morty' } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, {
              :environment => { 'HOME' => '/Users/morty', 'LC_ALL' => 'en_US.UTF-8' },
            }).and_return(true)
            shell_out.shell_out(cmd, options)
            expect(options[:environment].has_key?('LC_ALL')).to be false
          end
        end

        describe "and env is an option" do
          it "should not change env when set to nil" do
            options = { :env => { 'LC_ALL' => nil } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out(cmd, options)
          end

          it "should not change env when set to non-nil" do
            options = { :env => { 'LC_ALL' => 'de_DE.UTF-8'}}
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out(cmd, options)
          end

          it "should set env['LC_ALL'] to 'en_US.UTF-8' when 'LC_ALL' not present" do
            options = { :env => { 'HOME' => '/Users/morty' } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, {
              :env => { 'HOME' => '/Users/morty', 'LC_ALL' => 'en_US.UTF-8' },
            }).and_return(true)
            shell_out.shell_out(cmd, options)
          end

          it "should not mutate the options hash when it adds LC_ALL" do
            options = { :env => { 'HOME' => '/Users/morty' } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, {
              :env => { 'HOME' => '/Users/morty', 'LC_ALL' => 'en_US.UTF-8' },
            }).and_return(true)
            shell_out.shell_out(cmd, options)
            expect(options[:env].has_key?('LC_ALL')).to be false
          end
        end

        describe "and no env/environment option is present" do
          it "should add environment option and set environment['LC_ALL'] to 'en_US.UTF_8'" do
            options = { :user => 'morty' }
            expect(shell_out).to receive(:shell_out_command).with(cmd, {
              :user => 'morty', :environment => { 'LC_ALL' => 'en_US.UTF-8' },
            }).and_return(true)
            shell_out.shell_out(cmd, options)
          end
        end
      end

      describe "when the last argument is not a Hash" do
        it "should add environment options and set environment['LC_ALL'] to 'en_US.UTF-8'" do
          expect(shell_out).to receive(:shell_out_command).with(cmd, {
            :environment => { 'LC_ALL' => 'en_US.UTF-8' },
          }).and_return(true)
          shell_out.shell_out(cmd)
        end
      end

    end

    describe "#shell_out_with_systems_locale" do

      describe "when the last argument is a Hash" do
        describe "and environment is an option" do
          it "should not change environment['LC_ALL'] when set to nil" do
            options = { :environment => { 'LC_ALL' => nil } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out_with_systems_locale(cmd, options)
          end

          it "should not change environment['LC_ALL'] when set to non-nil" do
            options = { :environment => { 'LC_ALL' => 'en_US.UTF-8' } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out_with_systems_locale(cmd, options)
          end

          it "should no longer set environment['LC_ALL'] to nil when 'LC_ALL' not present" do
            options = { :environment => { 'HOME' => '/Users/morty' } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out_with_systems_locale(cmd, options)
          end
        end

        describe "and env is an option" do
          it "should not change env when set to nil" do
            options = { :env => { 'LC_ALL' => nil } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out_with_systems_locale(cmd, options)
          end

          it "should not change env when set to non-nil" do
            options = { :env => { 'LC_ALL' => 'en_US.UTF-8'}}
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out_with_systems_locale(cmd, options)
          end

          it "should no longer set env['LC_ALL'] to nil when 'LC_ALL' not present" do
            options = { :env => { 'HOME' => '/Users/morty' } }
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out_with_systems_locale(cmd, options)
          end
        end

        describe "and no env/environment option is present" do
          it "should no longer add environment option and set environment['LC_ALL'] to nil" do
            options = { :user => 'morty' }
            expect(shell_out).to receive(:shell_out_command).with(cmd, options).and_return(true)
            shell_out.shell_out_with_systems_locale(cmd, options)
          end
        end
      end

      describe "when the last argument is not a Hash" do
        it "should no longer add environment options and set environment['LC_ALL'] to nil" do
          expect(shell_out).to receive(:shell_out_command).with(cmd).and_return(true)
          shell_out.shell_out_with_systems_locale(cmd)
        end
      end
    end

  end
end
