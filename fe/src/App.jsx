import { Button, ButtonGroup,SliderField } from '@aws-amplify/ui-react';
import { useRef, useState } from 'react'
import '@aws-amplify/ui-react/styles.css';

function App() {
  let [location, setLocation] = useState("");
  let [gridSize, setGridSize] = useState(40);
  let [simSpeed,setSimSpeed] = useState(2);
  let [trees, setTrees] = useState([]);
  //c
  let [robots, setRobots] = useState([]);
  let [probability,setProbability] = useState(20)
  let [density,setDensity] = useState(20)
  let [south_wind,setSouth] = useState(20)
  let [west_wind,setWest] = useState(20)
  let [jump_prob,setJpb] = useState(100)
   
  const [checked, setChecked] = useState(false)
  const burntTrees = useRef(null);
  const running = useRef(null);

  // const [startTime, setStartTime] = useState(null);
  const [simulationDuration, setSimulationDuration] = useState(null);
  const [averageMovements, setAverageMovements] = useState(null);
  const [stdDeviationMovements, setStdDeviationMovements] = useState(null);
  if(simulationDuration){ 
    console.log("duration seconds", simulationDuration)
  }

  if(averageMovements) {
    console.log("average movements", averageMovements)
  }

  if(stdDeviationMovements) {
    console.log("standard deviation", stdDeviationMovements)
  }


  let setup = () => {
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({den: density})
    }).then(resp => resp.json())
    .then(data => {
      setLocation(data["Location"]);
      setTrees(data["trees"]);
      //c
      setRobots(data["robots"])
    });
  }


  let handleStart = () => {
    const startTime = Date.now()  // Start the timer
    setSimulationDuration(null);
    burntTrees.current = [];
    running.current = setInterval(() => {
    fetch("http://localhost:8000" + location)
    .then(res => res.json())
    .then(data => {
      // console.log(data)
      if (data.simulation_done) {
        clearInterval(running.current); // Stop interval first
        handleStop();
        const endTime = Date.now();
        setSimulationDuration((endTime - startTime) / 1000);  // Duration in seconds
        const movements = data.robots.map(robot => robot.m_count);
        const totalMovements = data.robots.reduce((acc, robot) => acc + robot.m_count, 0);
        const average = totalMovements / data.robots.length;
        setAverageMovements(average);
        const variance = movements.reduce((acc, count) => acc + Math.pow(count - average, 2), 0) / movements.length;
        const stdDev = Math.sqrt(variance);
        setStdDeviationMovements(stdDev);
      }
      let burnt = data["trees"].filter(t => t.status == "burnt").length / data["trees"].length;
      burntTrees.current.push(burnt);
      setTrees(data["trees"]);
      setRobots(data["robots"]);

      
    });
  }, 1000/simSpeed );
};

  let handleStop = () => {
   clearInterval(running.current);
  };

  let burning = trees.filter(t => t.status == "burning").length;
  //if (burning == 0) handleStop();
  let offset = (500 - gridSize * 12) / 2;

  return (
    <>
      <ButtonGroup variation="primary">
        <Button onClick={setup}>Setup</Button>
        <Button onClick={handleStart}>Start</Button>
        <Button onClick={handleStop}>Stop</Button>
      </ButtonGroup>

 
<SliderField label="simulation speed" min={1} max={40} step={10}
    value={simSpeed} onChange={setSimSpeed} />
<SliderField label="Box Density" min={20} max={100} step={20}
    value={density} onChange={setDensity} />




      <svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" style={{backgroundColor:"black"}}>
      <rect x={13} y={0} width={93} height={500} style={{fill: "green"}}></rect>
      <rect x={13} y={0} width={93} height={35} style={{fill: "red"}}></rect>
      <rect x={110} y={0} width={93} height={500} style={{fill: "green"}}></rect>
      <rect x={110} y={0} width={93} height={35} style={{fill: "red"}}></rect>
      <rect x={207} y={0} width={93} height={500} style={{fill: "green"}}></rect>
      <rect x={207} y={0} width={93} height={35} style={{fill: "red"}}></rect>
      <rect x={304} y={0} width={93} height={500} style={{fill: "green"}}></rect>
      <rect x={304} y={0} width={93} height={35} style={{fill: "red"}}></rect>
      <rect x={401} y={0} width={93} height={500} style={{fill: "green"}}></rect>
      <rect x={401} y={0} width={93} height={35} style={{fill: "red"}}></rect>
      <rect x={430} y={25} width={15} height={10} style={{fill: "pink"}}></rect>
      <rect x={335} y={25} width={15} height={10} style={{fill: "pink"}}></rect>
      <rect x={238} y={25} width={15} height={10} style={{fill: "pink"}}></rect>
      <rect x={154} y={25} width={15} height={10} style={{fill: "pink"}}></rect>
      <rect x={46} y={25} width={15} height={10} style={{fill: "pink"}}></rect>
      {
        trees.map(tree =>
          <image
            key={tree["id"]}
            x={offset + 12*(tree["pos"][0] - 1)}
            y={offset + 12*(tree["pos"][1] - 1)}
            width={15} href={
              tree["status"] === "green" ? "./megacaja20.svg" :
              (tree["status"] === "burning" ? "./megaroja20.svg" :
                "./burnttree.svg")
            }
          />
        )
      }
      {
        robots.map(tree =>
          <image
            key={tree["id"]}
            x={offset + 12*(tree["pos"][0] - 1)}
            y={offset + 12*(tree["pos"][1] - 1)}
            width={15} href={"./robot1.png"}
          />
        )
      }
      </svg>

    </>
  )
}

export default App
