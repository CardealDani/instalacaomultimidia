/* MVP 5.0: Zona Segura e Corrida para Vitória
   Conceito: Se passou do último obstáculo, corre automático para a próxima fase.
*/

// --- VARIÁVEIS DO JOGO ---
int fase = 1;
int maxPulos = 3; 
int pulosRestantes;
// Novos Estados: "CORRENDO_VITORIA" (Automático após o último buraco)
String estadoJogo = "CALIBRANDO"; 

// --- FÍSICA ---
float playerX, playerY;
float velocidadeX = 5;
float velocidadeY = 0;
float forcaPulo = -13; 
float gravidade = 0.5; 

// --- AMBIENTE ---
float chaoY = 300;
float tetoY = 0;
float fimDoPerigo = 0; // Armazena a coordenada X onde acaba o último buraco

ArrayList<PVector> buracos = new ArrayList<PVector>();

void setup() {
  size(800, 400);
  iniciarNovaFase();
}

void draw() {
  background(30); 
  
  // 1. MODO CALIBRAÇÃO (Parado pensando)
  if (estadoJogo.equals("CALIBRANDO")) {
    gravidade = map(mouseX, 0, width, 0.3, 1.8);
    desenharTrajetoria();
    
    // Verifica derrota por falta de combustível
    if (pulosRestantes <= 0) {
      estadoJogo = "GAMEOVER";
    }
  }

  // 2. MODO AÇÃO (Pulo ou Corrida Final)
  if (estadoJogo.equals("PULANDO") || estadoJogo.equals("CORRENDO_VITORIA")) {
    atualizarFisica();
  }
  
  // --- RENDERIZAÇÃO ---
  desenharCenario();
  desenharPersonagem();
  desenharInterface();
}

void atualizarFisica() {
  // Movimento Horizontal
  playerX += velocidadeX;
  
  // Se estiver pulando, aplica gravidade. Se estiver correndo na vitória, Y fica fixo.
  if (estadoJogo.equals("PULANDO")) {
    playerY += velocidadeY;
    velocidadeY += gravidade;
  }
  
  // -- COLISÃO TETO --
  if ((playerY - 15) < tetoY) {
    playerY = tetoY;
    registrarFalha(); 
  }
  
  // -- COLISÃO CHÃO --
  if (playerY >= chaoY) {
    
    // 1. Verifica Buracos
    boolean caiuNoBuraco = false;
    for (PVector b : buracos) {
      if (playerX > b.x && playerX < b.x + b.y) {
        caiuNoBuraco = true;
        break; 
      }
    }
    
    if (caiuNoBuraco) {
      registrarFalha();
    } else {
      // 2. ATERRISAGEM SEGURA
      playerY = chaoY;
      velocidadeY = 0;
      
      // AQUI ESTÁ A MUDANÇA:
      // Verifica se já passou do "fim do perigo" (último buraco)
      if (playerX > fimDoPerigo) {
        estadoJogo = "CORRENDO_VITORIA"; // Não para mais, vai direto
      } else {
        // Ainda tem buraco na frente, então PARA.
        if (estadoJogo.equals("PULANDO")) {
           estadoJogo = "CALIBRANDO";
        }
      }
      
      // Troca de fase ao sair da tela
      if (playerX > width) {
        proximaFase();
      }
    }
  }
}

void registrarFalha() {
  estadoJogo = "FALHA";
}

void desenharTrajetoria() {
  stroke(255, 255, 0, 100);
  strokeWeight(3);
  noFill();
  
  beginShape();
  float simX = playerX;
  float simY = playerY;
  float simVelY = forcaPulo;
  
  if (pulosRestantes > 0) {
    for (int i = 0; i < 90; i++) {
      vertex(simX, simY);
      simX += velocidadeX;
      simY += simVelY;
      simVelY += gravidade;
      if (simY > chaoY) break;
    }
  }
  endShape();
  noStroke();
}

void desenharCenario() {
  // Teto
  fill(255, 50, 50, 50);
  rect(0, 0, width, 20);
  
  // Chão
  fill(100);
  rect(0, chaoY + 20, width, height - chaoY); 
  
  // Buracos
  fill(50, 0, 0); 
  for (PVector b : buracos) {
    rect(b.x, chaoY + 20, b.y, height - chaoY);
  }
  
  // (Opcional) Bandeira verde indicando onde é seguro
  fill(0, 255, 0, 50);
  rect(fimDoPerigo, chaoY + 25, 10, 20);
}

void desenharPersonagem() {
  pushMatrix(); // Salva o sistema de coordenadas atual
  translate(playerX + 15, playerY + 15); // Move o ponto zero para o centro do player
  
  if (estadoJogo.equals("PULANDO") || estadoJogo.equals("CORRENDO_VITORIA")) {
    rotate(frameCount * 0.1); // Efeito de "Rodar" enquanto se move
  }
  
  fill(0, 150, 255);
  rectMode(CENTER);
  rect(0, 0, 30, 30); // Desenha no 0,0 (que agora é o centro do player)
  rectMode(CORNER);
  popMatrix(); // Restaura o sistema para desenhar o resto
}

void desenharInterface() {
  fill(255);
  textSize(20);
  textAlign(LEFT);
  text("Fase: " + fase, 20, 50);
  text("Gravidade: " + nf(gravidade, 1, 2), 20, 80);
  
  text("Pulos:", 20, 110);
  for(int i=0; i<maxPulos; i++) {
    if(i < pulosRestantes) fill(0, 200, 255); 
    else fill(80); 
    rect(100 + (i*25), 95, 15, 15);
  }
  
  textAlign(CENTER);
  if (estadoJogo.equals("FALHA")) {
    fill(255, 50, 50);
    textSize(30);
    text("FALHOU!", width/2, height/2);
    textSize(16);
    text("R para reiniciar", width/2, height/2 + 30);
  } else if (estadoJogo.equals("GAMEOVER")) {
    fill(255, 100, 0);
    textSize(30);
    text("SEM ENERGIA!", width/2, height/2);
    textSize(16);
    text("R para reiniciar", width/2, height/2 + 30);
  } else if (estadoJogo.equals("CORRENDO_VITORIA")) {
    fill(0, 255, 0);
    text("SUCESSO! >>", width/2, height/2 - 50);
  }
}

void iniciarNovaFase() {
  playerX = 50;
  playerY = chaoY;
  velocidadeY = 0;
  estadoJogo = "CALIBRANDO";
  pulosRestantes = maxPulos; 
  gerarBuracos();
}

void gerarBuracos() {
  buracos.clear();
  fimDoPerigo = 0; // Reinicia o cálculo do perigo
  
  boolean doisBuracos = (fase >= 2); 
  
  // Buraco 1
  float b1X = random(200, 350);
  float b1W = random(80, 120);
  buracos.add(new PVector(b1X, b1W));
  
  // Atualiza onde acaba o perigo
  fimDoPerigo = b1X + b1W;
  
  if (doisBuracos) {
    float b2X = b1X + b1W + random(120, 200); 
    float b2W = random(80, 120);
    if (b2X + b2W < width - 20) {
      buracos.add(new PVector(b2X, b2W));
      // Se adicionou o segundo, o perigo acaba depois dele
      fimDoPerigo = b2X + b2W;
    }
  }
}

void proximaFase() {
  fase++;
  iniciarNovaFase();
}

void keyPressed() {
  if (key == ' ') {
    if (estadoJogo.equals("CALIBRANDO") && pulosRestantes > 0) {
      velocidadeY = forcaPulo;
      estadoJogo = "PULANDO";
      pulosRestantes--; 
    }
  }
  if (key == 'r' || key == 'R') {
    if (estadoJogo.equals("FALHA") || estadoJogo.equals("GAMEOVER")) {
      iniciarNovaFase(); 
    }
  }
}
