'use client'
import { useRef, useState } from "react";
import styles from "./page.module.css";
import { Button } from "@mui/material";

export default function Home() {
  let [location, setLocation] = useState("");
  let [trees, setTrees] = useState([]);
  let gridSize = 5;
  const running = useRef(null);

  let setup = () => {
    console.log("Hola");
    fetch("http://localhost:8000/simulations", {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    }).then(resp => resp.json())
    .then(data => {
      setLocation(data["Location"]);
      setTrees(data["trees"]);
    });
  }

  const handleStart = () => {
    running.current = setInterval(() => {
      fetch("http://localhost:8000" + location)
      .then(res => res.json())
      .then(data => {
        setTrees(data["trees"]);
      });
    }, 500);
  };

  const handleStop = () => {
    clearInterval(running.current);
  }

  let burning = trees.filter(t => t.status == "burning").length;

  if (burning == 0)
    handleStop();

  let offset = (500 - gridSize * 12) / 2;
  return (
    <main className={styles.main}>
      <div>
        <Button variant={"contained"} onClick={setup}>
          Setup
        </Button>
        <Button variant={"contained"} onClick={handleStart}>
          Start
        </Button>
        <Button variant={"contained"} onClick={handleStop}>
          Stop
        </Button>
      </div>
      <svg width="400" height="400" xmlns="http://www.w3.org/2000/svg" style={{backgroundColor:"black"}}>
      {
        trees.map(tree => 
          <image 
            key={tree["id"]} 
            x={offset + 12*(tree["pos"][0] - 1)} 
            y={offset + 12*(tree["pos"][1] - 1)} 
            width={15} href={
              tree["status"] === "green" ? "./greentree.svg" :
              (tree["status"] === "burning" ? "./burningtree.svg" : 
                "./burnttree.svg")
            }
          />
        )
      }
      </svg>
    </main>
  );
}
