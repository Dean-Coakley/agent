package utils

import (
	"github.com/nginx/agent/sdk/v2"
	"github.com/nginx/agent/sdk/v2/proto"
	"github.com/nginx/agent/v2/src/core"
	"github.com/stretchr/testify/mock"
)

type MockNginxBinary struct {
	mock.Mock
}

func GetDetailsMap() map[string]*proto.NginxDetails {
	return map[string]*proto.NginxDetails{
		"12345": {
			NginxId:         "12345",
			Version:         "1.2.1",
			ConfPath:        "/var/conf",
			ProcessId:       "123",
			ProcessPath:     "/path/to/nginx",
			StartTime:       1564894894,
			BuiltFromSource: false,
			LoadableModules: []string{},
			RuntimeModules:  []string{},
			Plus: &proto.NginxPlusMetaData{
				Enabled: true,
				Release: "1.2.1",
			},
			Ssl:           &proto.NginxSslMetaData{},
			StatusUrl:     "",
			ConfigureArgs: []string{},
		},
	}
}

func GetMockNginxBinary() *MockNginxBinary {
	binary := NewMockNginxBinary()

	binary.On("GetNginxDetailsMapFromProcesses", mock.Anything).Return(GetDetailsMap())
	binary.On("GetNginxIDForProcess", mock.Anything).Return(GetDetailsMap())
	binary.On("GetNginxDetailsFromProcess", mock.Anything).Return(GetDetailsMap()["12345"])

	return binary
}

func (m *MockNginxBinary) GetNginxDetailsByID(nginxID string) *proto.NginxDetails {
	args := m.Called(nginxID)
	return args.Get(0).(*proto.NginxDetails)
}

func (m *MockNginxBinary) GetChildProcesses() map[string][]*proto.NginxDetails {
	args := m.Called()
	return args.Get(0).(map[string][]*proto.NginxDetails)
}

func (m *MockNginxBinary) WriteConfig(config *proto.NginxConfig) (*sdk.ConfigApply, error) {
	args := m.Called(config)
	confApply := args.Get(0).(*sdk.ConfigApply)

	return confApply, args.Error(1)
}

func (m *MockNginxBinary) ReadConfig(path, nginxId, systemId string) (*proto.NginxConfig, error) {
	args := m.Called(path, nginxId, systemId)
	config := args.Get(0).(*proto.NginxConfig)
	err := args.Error(1)

	return config, err
}

func (m *MockNginxBinary) Start(nginxId, bin string) error {
	m.Called(nginxId, bin)
	return nil
}

func (m *MockNginxBinary) Stop(processId, bin string) error {
	m.Called(processId, bin)
	return nil
}

func (m *MockNginxBinary) Reload(processId, bin string) error {
	m.Called(processId, bin)
	return nil
}

func (m *MockNginxBinary) ValidateConfig(processId, bin, configLocation string, config *proto.NginxConfig, configApply *sdk.ConfigApply) error {
	args := m.Called(processId, bin, configLocation, config, configApply)
	return args.Error(0)
}

func (m *MockNginxBinary) GetNginxDetailsMapFromProcesses(nginxProcesses []core.Process) map[string]*proto.NginxDetails {
	args := m.Called(nginxProcesses)
	return args.Get(0).(map[string]*proto.NginxDetails)
}

func (m *MockNginxBinary) UpdateNginxDetailsFromProcesses(nginxProcesses []core.Process) {
	m.Called(nginxProcesses)
}

func (m *MockNginxBinary) GetNginxIDForProcess(nginxProcess core.Process) string {
	args := m.Called(nginxProcess)
	return args.String(0)
}

func (m *MockNginxBinary) GetNginxDetailsFromProcess(nginxProcess core.Process) *proto.NginxDetails {
	args := m.Called(nginxProcess)
	return args.Get(0).(*proto.NginxDetails)
}

func (m *MockNginxBinary) UpdateLogs(existing map[string]string, newLogs map[string]string) bool {
	args := m.Called(existing, newLogs)
	return args.Bool(0)
}

func (m *MockNginxBinary) GetAccessLogs() map[string]string {
	args := m.Called()
	return args.Get(0).(map[string]string)
}

func (m *MockNginxBinary) GetErrorLogs() map[string]string {
	args := m.Called()
	return args.Get(0).(map[string]string)
}

func NewMockNginxBinary() *MockNginxBinary {
	return &MockNginxBinary{}
}

var _ core.NginxBinary = NewMockNginxBinary()
