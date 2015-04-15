class structure {
  int ID;
  char type;
  tower t;
  farm f;
  
  structure(char tp, int id) {
    ID = id;
    type = tp;
    switch (type) {
      case 'b':
        type = 'b';
        f = new farm(ID);
        break;
      case 'r':
      case 'p':
      case 'i':
      case 'l':
      case 'g':
        type = 't';
        t = new tower(type, ID);
        break;
    }
  }
}

class farm {
  int ID;
  float angle; // angle of farm's production rotation platform
  PImage base; // farm base
  PImage rotator; // farm rotation platform
  float radius = 50;
  int xpos; // x position of center of farm
  int ypos; // y position of center of farm
  float shield;
  float maxShield;
  float baseMaxShield;
  float health;
  float maxHealth = 100;
  int productionSpeed;
  int baseProductionSpeed;
  float shieldRegen;
  float baseShieldRegen;
  int shieldUpgrades = 0;
  int productionSpeedUpgrades = 0;
  int shieldRegenUpgrades = 0;
  int shieldButtons[] = new int[5];
  int productionSpeedButtons[] = new int[5];
  int shieldRegenButtons[] = new int[5];
  String button1text;
  String button2text;
  String button3text;
  String nametext;
  boolean inTransit = true;
  boolean wasInTransit = true;
  boolean conflict = false;
  Panel upgradePanel;
  /* type is the turret type
   * r: default rail gun
   * l: plasmagun
   * i: freeze gun
   */
  Body farm_body;

  // constructor function, initializes the tower
  farm(int id) {
    ID = id;
    angle = 0;

    xpos = round(mouse_x);
    ypos = round(mouse_y);

    baseMaxShield = 50;
    baseProductionSpeed = 1;
    baseShieldRegen = 1;
    base = loadImage("assets/bioreactor/BioGen Base-01.png");
    rotator = loadImage("assets/bioreactor/BioGen Top-01.png");
    nametext = "Bioreactor";
    button1text = "Shield Strength";
    button2text = "Production Speed";
    button3text = "Shield Regeneration";
    maxShield = baseMaxShield*(shieldUpgrades+1);
    shield = maxShield;
    productionSpeed = baseProductionSpeed*(productionSpeedUpgrades+1);
    shieldRegen = baseShieldRegen*(shieldRegenUpgrades+1);
    upgradePanel = new Panel(2000,1800,0,0,false, 200);
    upgradePanel.enabled = false;
    upgradePanel.createTextBox(2000,200,100,-800,new StringPass() { public String passed() { return ("Upgrade your " + nametext + " ID# " + the_player.selectedStructure.f.ID); } },80, false);
    upgradePanel.createTextBox(2000,200,0,-800,"",80, true);
    upgradePanel.createButton(200,200,-900,-800,"Close",60,220,0,0,new ButtonPress() { public void pressed() {
      upgradePanel.enabled = false;
      if(state == State.STAGED)state = State.RUNNING; } });
    for (int c = 0; c < 5; c++) {
      if (c > 0) {
        shieldButtons[c] = upgradePanel.createButton(420, 280, -600, 900-((5-c)*280),button1text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeShield(); } });
        upgradePanel.buttons.get(shieldButtons[c]).grayed = true;
        productionSpeedButtons[c] = upgradePanel.createButton(420, 280, 0, 900-((5-c)*280),button2text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeProductionSpeed(); } });
        upgradePanel.buttons.get(productionSpeedButtons[c]).grayed = true;
        shieldRegenButtons[c] = upgradePanel.createButton(420, 280, 600, 900-((5-c)*280),button3text + "\nX"+ (c+2) + "\n(Locked)", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeShieldRegen(); } });
        upgradePanel.buttons.get(shieldRegenButtons[c]).grayed = true;
      }
      else {
        shieldButtons[c] = upgradePanel.createButton(420, 280, -600, 900-((5-c)*280),button1text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeShield(); } });
        productionSpeedButtons[c] = upgradePanel.createButton(420, 280, 0, 900-((5-c)*280),button2text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeProductionSpeed(); } });
        shieldRegenButtons[c] = upgradePanel.createButton(420, 280, 600, 900-((5-c)*280),button3text + "\nX"+ (c+2) + "\n100$", 50, 255, (255-(c*51)), 0, new ButtonPress() { public void pressed() { the_player.selectedStructure.f.upgradeShieldRegen(); } });
      }
    }
    the_player.upgradepanels.add(upgradePanel);
  }

  void update() {
    if (!inTransit && wasInTransit) { // create a body for a just-placed farm
      BodyDef bd = new BodyDef();
      bd.position.set(box2d.coordPixelsToWorld(new Vec2(0+xpos, 17*(radius/80)+ypos)));
      bd.type = BodyType.STATIC;
      bd.linearDamping = 0.9;
      farm_body = box2d.createBody(bd);
      CircleShape sd = new CircleShape();
      sd.m_radius = box2d.scalarPixelsToWorld(radius); //radius;
      FixtureDef fd = new FixtureDef();
      fd.filter.categoryBits = 2; // food is in filter category 2
      fd.filter.maskBits = 65531; // doesn't interact with projectiles
      fd.shape = sd;
      fd.density = 100;
      farm_body.createFixture(fd);
      farm_body.setUserData(this);
      wasInTransit = false;
    }
    if (inTransit) {
      if (!wasInTransit) {
        farm_body.setUserData(null);
        for (Fixture f = farm_body.getFixtureList(); f != null; f = f.getNext())
          f.setUserData(null);
        box2d.destroyBody(farm_body); // destroy the body of a just-picked-up farm
      }
      wasInTransit = true;
      xpos = round(mouse_x);
      ypos = round(mouse_y);
      conflict = false;
      for (structure s : the_player.structures) { //check for overlap with existing structures
        if (s != the_player.pickedup) {
          if (s.type == 'b')
            if (sqrt((s.f.xpos-xpos)*(s.f.xpos-xpos)+(s.f.ypos-ypos)*(s.f.ypos-ypos)) <= radius*2)
              conflict = true;
          else if (sqrt((s.t.xpos-xpos)*(s.t.xpos-xpos)+(s.t.ypos-ypos)*(s.t.ypos-ypos)) <= radius*2)
            conflict = true;
        }
      } // and check if the farm is out-of-bounds
      if (xpos < ((-1*(worldWidth/2))+radius) || xpos > ((worldWidth/2)-radius) || ypos < ((-1*(worldHeight/2))+radius) || ypos > ((worldHeight/2)-radius))
        conflict = true;
    }
    else if (state == State.RUNNING) { // farm is placed and running
      the_player.money += productionSpeed; // this is the point of farms, right now
      angle += (productionSpeed*PI/16);
      if (angle > 2*PI) angle -= 2*PI;
      if (shield < maxShield) shield += shieldRegen;
    }
  }

  void display() {
    image(base,xpos-(radius*((float)128/80)),ypos-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);

    pushMatrix();
    translate(xpos, ypos);
    rotate(angle);
    image(rotator,-(radius*((float)128/80)),-(radius*((float)128/80)), (radius*((float)128/80))*2, (radius*((float)128/80))*2);
    popMatrix();

    // draw farm health bar
    noFill();
    stroke(0);
    rect(xpos, ypos-42, 0.1*maxHealth, 12);
    noStroke();
    fill(100, 255, 100);
    rect(xpos, ypos-42, 0.1*health, 12);

    // draw farm shield bar
    noFill();
    stroke(0);
    rect(xpos, ypos-30, 0.1*maxShield, 12);
    noStroke();
    fill(20, 200, 255);
    rect(xpos, ypos-30, 0.1*shield, 12);

    if (inTransit) {
    // draw the outline of the farm's box2D body
      pushMatrix();
      translate(xpos,ypos);
      fill(0, 0, 0, 0);
      if (conflict)stroke(255,0,0);
      else stroke(0,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
      for (structure s : the_player.structures) { // draw the outlines of all the other structure's bodies
        if (s != the_player.pickedup) {
          pushMatrix();
          if (s.type == 'b') translate(box2d.getBodyPixelCoord(s.f.farm_body).x, box2d.getBodyPixelCoord(s.f.farm_body).y);
          else translate(box2d.getBodyPixelCoord(s.t.tower_body).x, box2d.getBodyPixelCoord(s.t.tower_body).y);
          fill(0, 0, 0, 0);
          stroke(0);
          ellipse(0, 0, radius*2, radius*2);
          stroke(0);
          popMatrix();
        }
      }
    }
    else if (the_player.selectedStructure != null && the_player.selectedStructure.ID == ID) {
      pushMatrix();
      translate(box2d.getBodyPixelCoord(farm_body).x, box2d.getBodyPixelCoord(farm_body).y);
      fill(0, 0, 0, 0);
      stroke(255,255,0);
      ellipse(0, 0, radius*2, radius*2);
      stroke(0);
      popMatrix();
    }
  }
  
  void upgradeShield() {
    if (shieldUpgrades > 4)return;
    if (the_player.money < ((((byte)1)<<(shieldUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(shieldUpgrades*3))*100);
    upgradePanel.buttons.get(shieldButtons[shieldUpgrades]).button_text = button1text + "\nX"+ (shieldUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(shieldButtons[shieldUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (shieldUpgrades < 4) {
      upgradePanel.buttons.get(shieldButtons[shieldUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(shieldButtons[shieldUpgrades+1]).button_text = button1text + "\nX"+ (shieldUpgrades+3) + "\n" + (((byte)1)<<((shieldUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds("Upgrade_01");
    
    shieldUpgrades++;
    
    float shielddifference = (-1*maxShield);
    maxShield = baseMaxShield*(shieldUpgrades+1);
    shielddifference += maxShield;
    shield += shielddifference;
  }
  
  void upgradeProductionSpeed() {
    if (productionSpeedUpgrades > 4)return;
    if (the_player.money < ((((byte)1)<<(productionSpeedUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(productionSpeedUpgrades*3))*100);
    upgradePanel.buttons.get(productionSpeedButtons[productionSpeedUpgrades]).button_text = button2text + "\nX"+ (productionSpeedUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(productionSpeedButtons[productionSpeedUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (productionSpeedUpgrades < 4) {
      upgradePanel.buttons.get(productionSpeedButtons[productionSpeedUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(productionSpeedButtons[productionSpeedUpgrades+1]).button_text = button2text + "\nX"+ (productionSpeedUpgrades+3) + "\n" + (((byte)1)<<((productionSpeedUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds( "Upgrade_01" );
    
    productionSpeedUpgrades++;
    
    productionSpeed = baseProductionSpeed*(productionSpeedUpgrades+1);
  }
  
  void upgradeShieldRegen() {
    if (shieldRegenUpgrades > 4)return;
    if (the_player.money < ((((byte)1)<<(shieldRegenUpgrades*3))*100)) {
      println("You do not have sufficient funds to purchase this upgrade...");
      return;
    }
    the_player.money -= ((((byte)1)<<(shieldRegenUpgrades*3))*100);
    upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades]).button_text = button3text + "\nX"+ (shieldRegenUpgrades+2) + "\nPurchased!";
    upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades]).BP = new ButtonPress() { public void pressed() { println("You have already purchased this upgrade"); } };
    if (shieldRegenUpgrades < 4) {
      upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades+1]).grayed = false;
      upgradePanel.buttons.get(shieldRegenButtons[shieldRegenUpgrades+1]).button_text = button3text + "\nX"+ (shieldRegenUpgrades+3) + "\n" + (((byte)1)<<((shieldRegenUpgrades+1)*3)) + "00$";
    }
    
    if (playSound) PlaySounds( "Upgrade_01" );
    
    shieldRegenUpgrades++;
    
    shieldRegen = baseShieldRegen*(shieldRegenUpgrades+1);
  }
}
