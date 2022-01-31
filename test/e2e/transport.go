package e2e

import (
	"fmt"
	"os"
	"time"

	"github.com/hpcloud/tail"
)

type PriceMessage struct {
	Price struct {
		Wat string
		Val string
		Age int64
		R   string
		S   string
		V   string
	}
	Trace map[string]string
}

type Transport struct {
	filePath string
	tail     *tail.Tail
	ch       chan string
}

func NewTransport() (*Transport, error) {
	filePath, ok := os.LookupEnv("OMNIA_TRANSPORT_E2E_FILE")
	if !ok || filePath == "" {
		return nil, fmt.Errorf("OMNIA_TRANSPORT_E2E_FILE is not set")
	}

	err := os.Truncate(filePath, 0)
	if err != nil {
		return nil, fmt.Errorf("failed to truncate file: %w", err)
	}

	return &Transport{
		filePath: filePath,
	}, nil
}

func (t *Transport) Close() error {
	if t.tail == nil {
		return nil
	}
	err := t.tail.Stop()
	if err == nil {
		t.tail = nil
	}
	close(t.ch)
	t.ch = nil

	return err
}

func (t *Transport) IsEmpty() (bool, error) {
	if t.filePath == "" {
		return false, fmt.Errorf("IsEmpty: file path is not set")
	}
	content, err := os.ReadFile(t.filePath)
	if err != nil {
		return false, fmt.Errorf("IsEmpty: failed to check content: %w", err)
	}
	return len(content) == 0, nil
}

func (t *Transport) ReadChan() (chan string, error) {
	var err error

	if t.tail == nil {
		t.tail, err = tail.TailFile(t.filePath, tail.Config{Follow: true, MustExist: true, ReOpen: true})
		if err != nil {
			return nil, fmt.Errorf("failed to read file: %w", err)
		}
	}
	if t.ch == nil {
		t.ch = make(chan string)
	}
	go func() {
		for line := range t.tail.Lines {
			if t.ch == nil {
				return
			}
			t.ch <- line.Text
		}
	}()
	return t.ch, nil
}

func (t *Transport) WaitMsg(timeout time.Duration) (string, error) {
	if t.ch == nil {
		_, err := t.ReadChan()
		if err != nil {
			return "", fmt.Errorf("failed to create read channel: %w", err)
		}
	}
	select {
	case msg := <-t.ch:
		return msg, nil
	case <-time.After(timeout):
		return "", fmt.Errorf("timeout waiting for message")
	}
}
