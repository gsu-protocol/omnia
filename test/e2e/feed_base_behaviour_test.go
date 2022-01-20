package e2e

import (
	"fmt"
	"github.com/chronicleprotocol/infestor"
	"github.com/chronicleprotocol/infestor/origin"
	"testing"
	"time"

	"github.com/stretchr/testify/suite"
)

func TestFeedBaseBehaviourE2ESuite(t *testing.T) {
	suite.Run(t, new(FeedBaseBehaviourE2ESuite))
}

type FeedBaseBehaviourE2ESuite struct {
	SmockerAPISuite
}

func (s *FeedBaseBehaviourE2ESuite) TestBaseBehaviour() {
	// Setup price for BTC/USD
	err := infestor.NewMocksBuilder().
		Reset().
		Add(origin.NewExchange("bitstamp").WithSymbol("BTC/USD").WithPrice(1)).
		Add(origin.NewExchange("bittrex").WithSymbol("BTC/USD").WithPrice(1)).
		Add(origin.NewExchange("coinbase").WithSymbol("BTC/USD").WithPrice(1)).
		Add(origin.NewExchange("gemini").WithSymbol("BTC/USD").WithPrice(1)).
		Add(origin.NewExchange("kraken").WithSymbol("XXBT/ZUSD").WithPrice(1)).
		Deploy(s.api)

	s.Require().NoError(err)

	err = s.omnia.Start()
	s.Require().NoError(err)

	time.Sleep(time.Second * 10)

	err = s.omnia.Stop()
	s.Require().NoError(err)

	fmt.Println(s.omnia.StdoutString())
	fmt.Println(s.omnia.StderrString())
}
