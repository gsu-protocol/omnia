package e2e

import (
	"bytes"
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"syscall"
	"time"

	"github.com/chronicleprotocol/infestor/smocker"
	"github.com/stretchr/testify/suite"
)

const OmniaDefaultTimeout = 10 * time.Second

type SmockerAPISuite struct {
	suite.Suite
	api       smocker.API
	url       string
	omnia     *OmniaProcess
	transport *Transport
}

func (s *SmockerAPISuite) Setup() {
	smockerHost, exist := os.LookupEnv("SMOCKER_HOST")
	s.Require().True(exist, "SMOCKER_HOST env variable have to be set")

	s.api = smocker.API{
		Host: smockerHost,
		Port: 8081,
	}

	s.url = fmt.Sprintf("%s:8080", smockerHost)
}

func (s *SmockerAPISuite) Reset() {
	err := s.api.Reset(context.Background())
	s.Require().NoError(err)

	s.Require().Nil(s.transport)
	s.transport, err = NewTransport()
	s.Require().NoError(err)
}

func (s *SmockerAPISuite) Stop() {
	if s.omnia != nil {
		_ = s.omnia.Stop()
	}
	if s.transport != nil {
		_ = s.transport.Close()
		s.transport = nil
	}
}

func (s *SmockerAPISuite) SetupSuite() {
	s.Setup()
}

func (s *SmockerAPISuite) SetupTest() {
	s.Reset()
}

func (s *SmockerAPISuite) TearDownTest() {
	s.Stop()
}

type OmniaProcess struct {
	cmd     *exec.Cmd
	running bool
	Stdout  *bytes.Buffer
	Stderr  *bytes.Buffer
}

func NewOmniaProcess(ctx context.Context, params ...string) *OmniaProcess {
	var outb, errb bytes.Buffer

	cmd := exec.CommandContext(ctx, "omnia", params...)
	cmd.Stdout = &outb
	cmd.Stderr = &errb

	return &OmniaProcess{
		cmd:    cmd,
		Stdout: &outb,
		Stderr: &errb,
	}
}

func (op *OmniaProcess) StdoutString() string {
	return op.Stdout.String()
}

func (op *OmniaProcess) StderrString() string {
	return op.Stderr.String()
}

func (op *OmniaProcess) Start() error {
	op.cmd.Env = os.Environ()
	return op.cmd.Start()
}

func (op *OmniaProcess) WaitExit() (int, error) {
	if op.cmd == nil {
		return 0, fmt.Errorf("failed to wait for non existing command")
	}
	err := op.cmd.Wait()
	if err == nil {
		return 0, nil
	}
	if werr, ok := err.(*exec.ExitError); ok {
		if s := werr.Error(); s != "0" {
			if status, ok := werr.Sys().(syscall.WaitStatus); ok {
				return status.ExitStatus(), nil
			}
			return 1, nil
		}
	}
	return 0, fmt.Errorf("failed to get exit status core")
}

func (op *OmniaProcess) Stop() error {
	if op.cmd.Process == nil {
		return nil
	}
	return op.cmd.Process.Kill()
}

func call(command string, params ...string) (string, int, error) {
	cmd := exec.Command(command, params...)
	cmd.Env = os.Environ()

	out, err := cmd.Output()

	if werr, ok := err.(*exec.ExitError); ok {
		if s := werr.Error(); s != "0" {
			if status, ok := werr.Sys().(syscall.WaitStatus); ok {
				return "", status.ExitStatus(), fmt.Errorf("call to %s exited with exit code: %d", command, status.ExitStatus())
			}
			return "", 1, fmt.Errorf("call to %s exited with exit code: %s", command, s)
		}
	}

	return strings.TrimSpace(string(out)), 0, nil
}

func callSetzer(params ...string) (string, int, error) {
	cmd := exec.Command("setzer", params...)
	cmd.Env = os.Environ()

	out, err := cmd.Output()

	if werr, ok := err.(*exec.ExitError); ok {
		if s := werr.Error(); s != "0" {
			if status, ok := werr.Sys().(syscall.WaitStatus); ok {
				return "", status.ExitStatus(), fmt.Errorf("setzer exited with exit code: %d", status.ExitStatus())
			}
			return "", 1, fmt.Errorf("setzer exited with exit code: %s", s)
		}
	}

	return strings.TrimSpace(string(out)), 0, nil
}
